1. Установите Docker Desktop и запустите его.

2. Склонируйте репозиторий:

git clone <URL_РЕПОЗИТОРИЯ>
cd BD_CP

3. Создайте файл .env:

Copy-Item .env.example .env

4. Запустите проект:

docker compose up --build

5. Откройте приложение:

http://localhost:8000