import requests
import json
import time

# Telegram bot token ve chat ID
bot_token = '7531428937:AAHw3zz7_TcHJRfA904AwUV0thpYW0s5XeU'  # BotFather'dan aldığın token'ı buraya yapıştır
chat_id = '1324145008'  # Kendi chat ID'nizi buraya yazın

# DexScreener API URL'si
url = "https://api.dexscreener.com/token-profiles/latest/v1"

# Daha önce gönderilen tokenların dosyası
sent_tokens_file = 'sent_tokens.json'

# API'den token verilerini alıyoruz
def get_tokens_from_dex_screener():
    response = requests.get(url)
    if response.status_code == 200:
        return response.json()
    else:
        print("❌ DexScreener verisi alınamadı.")
        return []

# Geçmişte gönderilen tokenları dosyadan oku
def read_sent_tokens():
    try:
        with open(sent_tokens_file, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        return []

# Geçmişte gönderilen tokenları dosyaya kaydet
def save_sent_tokens(sent_tokens):
    with open(sent_tokens_file, 'w') as f:
        json.dump(sent_tokens, f)

# Solana bağlantılı ve Twitter bilgisi olan tokenları filtrele
def filter_tokens(tokens):
    solana_tokens = []
    for token in tokens:
        if token.get('chainId', '') == 'solana':
            # Twitter bağlantısı var mı kontrol et
            for link in token.get('links', []):
                if isinstance(link, dict) and link.get('type') == 'twitter':
                    solana_tokens.append({
                        'name': token.get('url', '').split('/')[-1],  # Token adı
                        'symbol': token.get('tokenAddress', '').upper(),  # Token adresi (symbol)
                        'dex_url': token.get('url', ''),  # DEX üzerindeki bağlantı
                    })
                    break  # Twitter linki bulunduysa diğer linkleri kontrol etmemize gerek yok
    return solana_tokens

# Telegram mesaj gönderme
def send_telegram_message(message):
    url = f'https://api.telegram.org/bot{bot_token}/sendMessage?chat_id={chat_id}&text={message}'
    response = requests.get(url)
    return response.json()

# Tokenları al, filtrele ve Telegram'a gönder
def get_solana_tokens_with_twitter():
    tokens = get_tokens_from_dex_screener()
    solana_tokens = filter_tokens(tokens)
    sent_tokens = read_sent_tokens()
    new_tokens = []

    if solana_tokens:
        message = "Yeni Twitter hesabı olan Solana bağlantılı tokenlar:\n"
        for token in solana_tokens:
            # Eğer token daha önce gönderilmemişse
            if token['dex_url'] not in sent_tokens:
                new_tokens.append(token['dex_url'])
                message += f"Token Adı: {token['name']}\n"
                message += f"Symbol: {token['symbol']}\n"
                message += f"DEX Linki: {token['dex_url']}\n\n"  # Arada boşluk bırakıyoruz

        if new_tokens:
            send_telegram_message(message)  # Mesajı Telegram'a gönder
            # Yeni tokenları dosyaya kaydet
            sent_tokens.extend(new_tokens)
            save_sent_tokens(sent_tokens)
        else:
            send_telegram_message("🚫 Yeni Twitter hesabı olan Solana tokenları bulunamadıyenii.")
    else:
        send_telegram_message("🚫 Solana bağlantılı tokenlar bulunamadıyeniii.")

# Sürekli çalıştırmak için
while True:
    get_solana_tokens_with_twitter()
    time.sleep(300)  # 5 dakika bekle
