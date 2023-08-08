#apt install libmariadb-dev-compat libmariadb-dev mariadb-client

requires 'Config::Tiny';
requires 'DBI';
requires 'DBD::mysql';
requires 'Carp';
requires 'Email::Address';
requires 'Log::Mini';

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::MonkeyMock';
    requires 'Test::Output';
};