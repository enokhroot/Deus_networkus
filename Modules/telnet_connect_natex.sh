#! /usr/bin/expect
#Используем модуль expect для того, чтобы принимать запросы и отвечать на них
set timeout -1
#Устанавливаем переменные, значения для которых приняли при вызове функции
set ip_address [lindex $argv 0]
set user [lindex $argv 1]
set pass [lindex $argv 2]
#Подключаемся с помощью telnet
spawn telnet $ip_address 23
#В ответ на запросы передаём ответы
expect "Username:"
send "$user\r"

expect "Password:"
send "$pass\r"

interact
