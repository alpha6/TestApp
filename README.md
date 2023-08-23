Устанавить зависимости:

    cpanm --installdeps .

Запускаем контейнер с базой и заливаем туда схему:

    bash ./start.sh

Контейнер вешается на порт 33060 и доступен снаружи.

Запуск тестов:
    
    prove t

Для запуска парсера:

    perl ./parser.pl --log_file=out

По итогу работы выведет в лог общее количество обработанных строк, строки залитых в message и log, а так же пропущенные строки:

    ...
    2023-08-17 19:05:52.998 [warn] No flag and int_id in string: 2012-02-13 15:10:35 SMTP connection from [194.226.65.146] (TCP/IP connection count = 1)
    2023-08-17 19:05:52.998 [warn] No flag and int_id in string: 2012-02-13 15:10:35 SMTP connection from nms.somehost.ru [194.226.65.146] closed by QUIT
    2023-08-17 19:05:53.192 [info] Total: 10000, messages: 1561, log: 8338, other: 101

Запуск web приложения:
    
    perl ./test-web daemon

Приложение доступно по адресу `http://localhost:3000/`
