# Деплой веб-версии Лежандр

## 1. Сборка веб-версии

### Предварительные требования
- Flutter SDK установлен (3.x рекомендуется)
- Поддержка веб-платформы включена

```bash
# Проверить, что веб поддерживается
flutter devices

# Если веб не включён, активировать
flutter config --enable-web
```

### Сборка production-версии

```bash
cd /path/to/lezhandr_app

# Сборка веб-версии
flutter build web --release

# Результат будет в: build/web/
```

### Опциональные флаги сборки

```bash
# С указанием базового URL (если приложение не в корне домена)
flutter build web --release --base-href "/lezhandr/"

# С конкретным dart-define для конфигурации
flutter build web --release --dart-define=API_URL=https://api.example.com
```

## 2. Структура сборки

После сборки в `build/web/` появятся файлы:

```
build/web/
├── index.html          # Главный HTML-файл
├── main.dart.js        # Скомпилированный JS (может быть несколькими файлами)
├── flutter.js          # Загрузчик Flutter
├── flutter_service_worker.js  # Service Worker для кэширования
├── icons/              # Иконки для PWA
├── assets/             # Статические ассеты
│   ├── assets/         # Картинки, шрифты и т.д.
│   └── fonts/          # Шрифты
└── manifest.json       # Манифест PWA
```

## 3. Настройка nginx

### Базовая конфигурация

Создайте файл `/etc/nginx/sites-available/lezhandr`:

```nginx
server {
    listen 80;
    server_name lezhandr.example.com;

    root /var/www/lezhandr;
    index index.html;

    # Gzip сжатие
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/x-javascript
        application/xml
        application/json;
    gzip_comp_level 6;

    # Кэширование статических файлов
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Service worker не кэшируем
    location ~* flutter_service_worker\.js$ {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        expires 0;
    }

    # SPA fallback - все запросы на index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Безопасность
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

### Конфигурация с SSL (Let's Encrypt)

```nginx
server {
    listen 80;
    server_name lezhandr.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name lezhandr.example.com;

    ssl_certificate /etc/letsencrypt/live/lezhandr.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/lezhandr.example.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    root /var/www/lezhandr;
    index index.html;

    # Gzip сжатие
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/x-javascript
        application/xml
        application/json;
    gzip_comp_level 6;

    # Кэширование статических файлов
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Service worker не кэшируем
    location ~* flutter_service_worker\.js$ {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        expires 0;
    }

    # SPA fallback
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Безопасность
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

## 4. Деплой

### Размещение файлов

```bash
# Создать директорию
sudo mkdir -p /var/www/lezhandr

# Скопировать сборку
sudo cp -r build/web/* /var/www/lezhandr/

# Установить права
sudo chown -R www-data:www-data /var/www/lezhandr
sudo chmod -R 755 /var/www/lezhandr
```

### Активация конфигурации nginx

```bash
# Создать симлинк
sudo ln -s /etc/nginx/sites-available/lezhandr /etc/nginx/sites-enabled/

# Проверить конфигурацию
sudo nginx -t

# Перезагрузить nginx
sudo systemctl reload nginx
```

## 5. Полный скрипт деплоя

Создайте `deploy.sh`:

```bash
#!/bin/bash
set -e

PROJECT_DIR="/path/to/lezhandr_app"
DEPLOY_DIR="/var/www/lezhandr"
SERVER_USER="user@lezhandr.example.com"

echo "Building Flutter web..."
cd $PROJECT_DIR
flutter build web --release

echo "Deploying to server..."
rsync -avz --delete build/web/ $SERVER_USER:$DEPLOY_DIR/

echo "Setting permissions on server..."
ssh $SERVER_USER "sudo chown -R www-data:www-data $DEPLOY_DIR && sudo chmod -R 755 $DEPLOY_DIR"

echo "Done!"
```

## 6. Обновление API URL

Если API находится на другом домене, нужно настроить CORS на бэкенде и обновить URL в приложении.

### Вариант 1: Через dart-define

```bash
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com
```

### Вариант 2: Через env.js (рекомендуется)

Создайте `web/env.js`:

```javascript
window.ENV = {
    API_BASE_URL: "https://api.example.com"
};
```

Добавьте в `web/index.html` перед закрывающим `</head>`:

```html
<script src="env.js"></script>
```

В коде используйте:

```dart
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: const bool.hasEnvironment('dart.library.js')
      ? (js.context['ENV']['API_BASE_URL'] as String)
      : 'http://localhost:8000',
);
```

## 7. Troubleshooting

### Белый экран после загрузки

1. Проверьте консоль браузера на ошибки
2. Убедитесь, что `index.html` правильно загружает `flutter.js`
3. Проверьте пути к ассетам

### Ошибки CORS

Настройте бэкенд для разрешения запросов с домена фронтенда:

```python
# FastAPI пример
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://lezhandr.example.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Проблемы с routing

Убедитесь, что nginx корректно отдаёт `index.html` для всех маршрутов:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

### Кэширование при обновлениях

При обновлении пользователи могут видеть старую версию из-за кэша. Решения:

1. Service Worker Flutter автоматически обновляется при изменении `main.dart.js`
2. Можно добавить версионирование в скрипт деплоя:

```bash
# Добавить метку времени к main.dart.js
TIMESTAMP=$(date +%s)
sed -i "s/main.dart.js/main.dart.js?v=$TIMESTAMP/" build/web/index.html
```

## 8. Мониторинг и логи

```bash
# Логи nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Статус nginx
sudo systemctl status nginx
```
