# -*- coding: utf-8 -*-
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

from flask import Flask, jsonify, request, send_from_directory, Response
from flask_cors import CORS
import threading
import time
import os
import json
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))  # crawler/ 目录本身

app = Flask(__name__)
CORS(app)

BIGMODEL_API_KEY = os.environ.get("BIGMODEL_API_KEY", "")

# 全局变量
crawling_active = False
crawling_thread = None
news_data = []
data_lock = threading.Lock()

MAX_DISPLAY_COUNT = 50
PAGE_SIZE = 3

import requests
from bs4 import BeautifulSoup
import re

spider_headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
}


def scrape_eol(limit=1):
    articles = []
    try:
        url = "https://news.eol.cn/"
        response = requests.get(url, headers=spider_headers, timeout=10)
        response.encoding = 'utf-8'
        soup = BeautifulSoup(response.text, 'html.parser')
        news_items = soup.select('a[href*="/news/"], a[href*="/202"], .news-item a, h3 a, h4 a')
        count = 0
        seen_titles = set()
        for item in news_items:
            if count >= limit:
                break
            title = item.get_text(strip=True)
            if title and 5 < len(title) < 200:
                href = item.get('href', '')
                if href and not href.startswith('http'):
                    href = requests.compat.urljoin(url, href)
                if title in seen_titles:
                    continue
                seen_titles.add(title)
                articles.append({
                    'source': '中国教育在线',
                    'title': title,
                    'url': href,
                    'crawl_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                })
                count += 1
    except Exception as e:
        print(f"EOL Error: {e}")
    return articles


def scrape_moe(limit=1):
    articles = []
    try:
        url = "http://www.moe.gov.cn/jyb_xwfb/gzdt_gzdt/"
        response = requests.get(url, headers=spider_headers, timeout=10)
        response.encoding = 'utf-8'
        soup = BeautifulSoup(response.text, 'html.parser')
        exclude = ['English', 'Русский', '无障碍', '设为', '收藏', '微博', '微信']
        news_items = soup.select('li a, .list a')
        count = 0
        seen_titles = set()
        for item in news_items:
            if count >= limit:
                break
            title = item.get_text(strip=True)
            if title and len(title) > 8 and not any(e in title for e in exclude):
                if re.search(r'[\u4e00-\u9fff]', title):
                    href = item.get('href', '')
                    if href and not href.startswith('http'):
                        href = requests.compat.urljoin(url, href)
                    if title in seen_titles:
                        continue
                    seen_titles.add(title)
                    articles.append({
                        'source': '教育部官网',
                        'title': title,
                        'url': href,
                        'crawl_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                    })
                    count += 1
    except Exception as e:
        print(f"MOE Error: {e}")
    return articles


def scrape_people(limit=1):
    articles = []
    try:
        url = "http://edu.people.com.cn/"
        response = requests.get(url, headers=spider_headers, timeout=10)
        response.encoding = 'utf-8'
        soup = BeautifulSoup(response.text, 'html.parser')
        news_items = soup.select('a[href*="/n1/"], a[href*="/n2/"], .news-item a, h3 a')
        count = 0
        seen_titles = set()
        for item in news_items:
            if count >= limit:
                break
            title = item.get_text(strip=True)
            if title and 5 < len(title) < 200:
                href = item.get('href', '')
                if href and href.startswith('/'):
                    href = requests.compat.urljoin(url, href)
                if title in seen_titles:
                    continue
                seen_titles.add(title)
                articles.append({
                    'source': '人民网教育',
                    'title': title,
                    'url': href,
                    'crawl_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                })
                count += 1
    except Exception as e:
        print(f"People Error: {e}")
    return articles


def _add_articles(articles, seen_titles):
    """将文章列表写入 news_data，返回实际新增条数。调用方需持有 data_lock。"""
    added = 0
    for article in articles:
        title = article['title']
        if title in seen_titles:
            continue
        seen_titles.add(title)
        news_data.append(article)
        added += 1
    # 超出上限时按时间顺序释放最旧的条目
    if len(news_data) > MAX_DISPLAY_COUNT:
        removed = news_data[:len(news_data) - MAX_DISPLAY_COUNT]
        del news_data[:len(removed)]
        for r in removed:
            seen_titles.discard(r['title'])
        sys.stdout.write(f"[SYS] Trimmed {len(removed)} old articles\n")
        sys.stdout.flush()
    return added


def background_crawling():
    global crawling_active, news_data
    seen_titles = set()

    sys.stdout.write("[SYS] Crawler started\n")
    sys.stdout.flush()

    methods = [
        ('China Education Online', scrape_eol),
        ('Ministry of Education', scrape_moe),
        ('People.com Education', scrape_people)
    ]

    # === 阶段一：启动时每个站点批量抓 20 条 ===
    sys.stdout.write("[SYS] Phase 1: bulk fetch 20 per site\n")
    sys.stdout.flush()
    for site_name, method in methods:
        if not crawling_active:
            break
        sys.stdout.write(f"[SYS] Bulk crawling: {site_name}\n")
        sys.stdout.flush()
        try:
            articles = method(limit=20)
            with data_lock:
                added = _add_articles(articles, seen_titles)
            sys.stdout.write(f"[SYS] Bulk +{added}, total: {len(news_data)}\n")
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(f"[SYS] Bulk error {site_name}: {e}\n")
            sys.stdout.flush()

    # === 阶段二：每 60 秒轮询一个站点，每次抓 1 条 ===
    sys.stdout.write("[SYS] Phase 2: slow poll, 1 per site per 60s\n")
    sys.stdout.flush()
    idx = 0
    while crawling_active:
        try:
            site_name, method = methods[idx % len(methods)]
            idx += 1

            sys.stdout.write(f"[SYS] Crawling: {site_name}\n")
            sys.stdout.flush()

            new_articles = method(limit=1)
            with data_lock:
                added = _add_articles(new_articles, seen_titles)

            if added:
                sys.stdout.write(f"[SYS] + new article, total: {len(news_data)}\n")
            else:
                sys.stdout.write(f"[SYS] No new data from {site_name}\n")
            sys.stdout.flush()

            for _ in range(60):
                if not crawling_active:
                    break
                time.sleep(1)

        except Exception as e:
            sys.stdout.write(f"[SYS] Error: {e}\n")
            sys.stdout.flush()
            time.sleep(5)

    sys.stdout.write("[SYS] Crawler stopped\n")
    sys.stdout.flush()


@app.route('/')
def serve_index():
    return send_from_directory(BASE_DIR, 'index.html')


@app.route('/api/news')
def get_news():
    page = request.args.get('page', 1, type=int)
    with data_lock:
        total = len(news_data)
        total_pages = max(1, (total + PAGE_SIZE - 1) // PAGE_SIZE)
        page = min(page, total_pages) if total > 0 else 1
        start = (page - 1) * PAGE_SIZE
        end = start + PAGE_SIZE
        return jsonify({
            'data': news_data[start:end],
            'page': page,
            'total_pages': total_pages,
            'total': total
        })


@app.route('/api/start', methods=['POST'])
def start_crawling():
    global crawling_active, crawling_thread
    if crawling_active:
        return jsonify({'success': False, 'message': '爬虫已在运行中'})
    crawling_active = True
    crawling_thread = threading.Thread(target=background_crawling)
    crawling_thread.daemon = True
    crawling_thread.start()
    return jsonify({'success': True, 'message': f'爬虫已启动，最多存储{MAX_DISPLAY_COUNT}条，每页{PAGE_SIZE}条'})


@app.route('/api/stop', methods=['POST'])
def stop_crawling():
    global crawling_active
    if not crawling_active:
        return jsonify({'success': False, 'message': '爬虫未运行'})
    crawling_active = False
    return jsonify({'success': True, 'message': '爬虫已停止'})


@app.route('/api/status')
def get_status():
    return jsonify({
        'active': crawling_active,
        'total_count': len(news_data),
        'max_display': MAX_DISPLAY_COUNT
    })


@app.route('/api/clear', methods=['POST'])
def clear_data():
    global news_data
    with data_lock:
        news_data = []
    return jsonify({'success': True, 'message': '数据已清空'})


@app.route('/api/health')
def health_check():
    return jsonify({'status': 'ok', 'message': '爬虫服务运行正常'})


@app.route('/api/chat', methods=['POST'])
def chat():
    data = request.json or {}
    messages = data.get('messages', [])

    system_msg = {
        "role": "system",
        "content": (
            "你是「数据洞察平台」的AI小助理，专注于国际学生阅读素养分析领域。"
            "基于PISA（国际学生评估项目）框架，帮助用户理解数据、解读政策、分析教学方法。"
            "回答要专业、清晰、有条理，适当使用数据和实例支撑观点，必要时使用标题、列表等结构化格式。"
        )
    }

    def generate():
        try:
            resp = requests.post(
                'https://open.bigmodel.cn/api/paas/v4/chat/completions',
                headers={
                    'Authorization': f'Bearer {BIGMODEL_API_KEY}',
                    'Content-Type': 'application/json'
                },
                json={
                    'model': 'glm-4-flash',
                    'messages': [system_msg] + messages,
                    'stream': True
                },
                stream=True,
                timeout=60
            )
            for line in resp.iter_lines():
                if line:
                    decoded = line.decode('utf-8')
                    if decoded.startswith('data: '):
                        yield decoded + '\n\n'
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)})}\n\n"

    return Response(
        generate(),
        mimetype='text/event-stream',
        headers={'Cache-Control': 'no-cache', 'X-Accel-Buffering': 'no'}
    )


if __name__ == '__main__':
    # 服务启动时自动开启爬虫
    crawling_active = True
    crawling_thread = threading.Thread(target=background_crawling)
    crawling_thread.daemon = True
    crawling_thread.start()

    print("=" * 50)
    print("Education News Crawler")
    print(f"Base: {BASE_DIR}")
    print(f"Access: http://localhost:5000")
    print("=" * 50)

    app.run(debug=False, host='0.0.0.0', port=5000, use_reloader=False)
