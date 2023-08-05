#apt install libmariadb-dev-compat libmariadb-dev mariadb-client

requires 'Config::Tiny';
requires 'DBI';
requires 'DBD::mysql';
requires 'Carp';

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::MonkeyMock';
    requires 'Test::Output';
};