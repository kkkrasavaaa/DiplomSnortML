# DiplomSnortML

![License](https://img.shields.io/badge/license-MIT-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)

![Snort Pig](https://gifdb.com/images/high/cute-pig-police-uniform-zwed2h4bl0uqi5jt.gif)

**DiplomSnortML** — це експериментальний проєкт, який об’єднує Snort3 із модулем машинного навчання SnortML. Він призначений для виявлення невідомих загроз, таких як SQL-ін’єкції, у контейнері Docker. Цей репозиторій містить усе необхідне, щоб створити, навчити та запустити модель машинного навчання для аналізу мережевого трафіку.

---

## Що це таке?

**SnortML** — це модуль для Snort3, який використовує машинне навчання, щоб знаходити підозрілі запити, навіть якщо вони не збігаються з традиційними правилами. Проєкт базується на ідеї від Dr. Brandon Stultz із Cisco Talos. Дізнайтесь більше у [блозі](https://blog.snort.org/2024/03/talos-launching-new-machine-learning.html) або перегляньте відео.

Цей репозиторій спрощує налаштування завдяки Docker, дозволяючи швидко протестувати Snort із підтримкою машинного навчання.

---

## Зміст

- [Як встановити](#як-встановити)
- [Як використовувати](#як-використовувати)
  - [Генерація трафіку](#генерація-трафіку)
  - [Налаштування правил](#налаштування-правил)
  - [Навчання моделі](#навчання-моделі)
  - [Запуск Snort](#запуск-snort)
- [Результати](#результати)
- [Висновки](#висновки)

---

## Як встановити

Щоб почати, виконайте ці прості кроки:

1. **Склонуйте репозиторій:**
   ```bash
   git clone https://github.com/kkkrasavaaa/DiplomSnortML.git
   cd DiplomSnortML
   ```

2. **Створіть Docker-образ:**
   ```bash
   docker build -t snort3ml .
   ```

3. **Запустіть контейнер:**
   ```bash
   docker run -it --name snort3ml_c snort3ml
   ```

   - Щоб повернутися до контейнера пізніше: `docker start snort3ml_c`
   - Щоб відкрити оболонку: `docker exec -it snort3ml_c /bin/bash`

4. **Перейдіть до прикладів:**
   ```bash
   cd /usr/local/src/libml/examples/classifier
   ```

---

## Як використовувати

### Генерація трафіку

Створіть файл `.pcap` із тестовим шкідливим трафіком:

1. **Налаштуйте віртуальне середовище:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

2. **Встановіть Scapy:**
   ```bash
   pip install scapy
   ```

3. **Згенеруйте трафік:**
   ```bash
   python3 pcapgen.py
   ```

4. **Перегляньте результат:**
   ```bash
   tcpdump -r simulated_sql_injection.pcap
   ```

### Налаштування правил

Додайте правило у файл `local.rules`, щоб Snort шукав SQL-ін’єкції. Ось приклад:

```plaintext
alert http any any -> any 80 (
    msg:"Можлива SQL-ін’єкція";
    flow:to_server,established;
    http_uri:path;
    content:"/php/admin_notification.php", nocase;
    http_uri:query;
    content:"foo=", nocase;
    pcre:"/1%27%20OR%201=1%2D%2D/i";
    reference:cve,2012-2998;
    classtype:web-application-attack;
    sid:1;
)
```

> **Важливо:** Це правило шукає лише точний збіг із `1' OR 1=1--`. SnortML допоможе знайти схожі запити.

### Навчання моделі

Навчіть модель на простому наборі даних:

```python
data = [
    { 'str': 'foo=1', 'attack': 0 },
    { 'str': 'foo=1%27%20OR%201=1%2D%2D', 'attack': 1 }
]
```

1. **Встановіть бібліотеки:**
   ```bash
   pip install numpy tensorflow
   ```

2. **Запустіть навчання:**
   ```bash
   ./train.py
   ```

> **Порада:** Додайте більше прикладів у дані, щоб модель стала точнішою.

### Запуск Snort

Проаналізуйте трафік із навченої моделлю:

```bash
snort -c /usr/local/snort/etc/snort/snort.lua --talos --lua 'snort_ml_engine = { http_param_model = "classifier.model" }; snort_ml = {}; trace = { modules = { snort_ml = {all =1 } } };' -r simulated_sql_injection.pcap
```

- `-c`: конфігурація Snort3.
- `--talos --lua`: підключення SnortML із моделлю.

---

## Результати

Після запуску Snort ви отримаєте:

- **Збіги з правилами:** Чи спрацювало правило (у нашому випадку — ні, бо шаблон не точний).
- **Сповіщення SnortML:** Модель виявить схожі атаки.

Приклад результату:

```plaintext
rule profile (all, sorted by total_time)
#       gid   sid rev    checks matches alerts time (us) avg/check avg/match avg/non-match timeouts suspends rule_time (%)
=       ===   === ===    ====== ======= ====== ========= ========= ========= ============= ======== ======== =============
1         1     1   0         1       0      0       112       112         0           112        0        0       0.2451
```

```plaintext
--------------------------------------------------
snort_ml
               uri_alerts: 1
                uri_bytes: 17
              libml_calls: 1
--------------------------------------------------
```

> **Що це означає?** SnortML визначив запит `foo=1' OR 2=3--` як шкідливий із ймовірністю 0.96, хоча правило його пропустило.

---

## Висновки

Цей проєкт показує, як машинне навчання може покращити Snort, виявляючи нові або змінені загрози. Для реального використання модель можна вдосконалювати, додаючи нові дані.
