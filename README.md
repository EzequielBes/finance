# AnalisadorFinanceiro

Plataforma de análise e planejamento financeiro pessoal.

## Stack
- **Backend:** Python + FastAPI + SQLite (SQLAlchemy async) + JWT
- **Frontend:** Vue.js 3 + Vite + Pinia

## Como rodar localmente

### Backend
```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Docs disponíveis em: http://localhost:8000/docs

### Frontend
```bash
cd frontend
npm install
npm run dev
```

Acesse: http://localhost:5173

### Rodar testes do backend
```bash
cd backend
source .venv/bin/activate
pytest -v
```

## Como rodar com Docker

```bash
docker compose up -d --build
```

- Backend: http://localhost:8000/docs
- Frontend: http://localhost:5173
- Dados do SQLite persistem no volume `backend_data` entre restarts.

Parar:
```bash
docker compose down
```

Parar e apagar os dados persistidos:
```bash
docker compose down -v
```
