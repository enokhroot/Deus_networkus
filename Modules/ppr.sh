#!/bin/bash

while : #Запускается основной цикл
do
cat << EOF
+-------------------------------------------------------------------------------+
|                               Модуль                                          |
|                    для проведения ППР на коммутаторах                         |
+-------------------------------------------------------------------------------+
EOF
    #Путь до папки со скриптами принимается при вызове скрипта
    path_to_script=$1
    date_=$(date +%Y)
    #Передача списка адресов в переменную
    ip_list="$path_to_script/Deus_networkus/ip_.txt"

    echo "Добро пожаловать в модуль для проведения ППР"
    echo "========================="
    echo "Введите имя пользователя:"
    read user_
    #Скрыть ввод пароля 
    stty_orig=$(stty -g)
    stty -echo 
    read -p "Введите пароль:" pass_
    #Возврат нормального ввода
    stty "$stty_orig"

    #Функция для передачи команд для проедения ППР
    function lets_go_ppr() {
        echo -e "\033[0;32mПодключение к $ip_\033[0m"
        echo "==========" > $ip_.ppr.txt
        echo "SHOW RUN" >> $ip_.ppr.txt
        echo "==========" >> $ip_.ppr.txt
        sshpass -p "$pass_" ssh -o StrictHostKeyChecking=no $user_@$ip_ "sh run" >> $ip_.ppr.txt
        echo "==========" >> $ip_.ppr.txt
        echo "SHOW LOG" >> $ip_.ppr.txt
        echo "==========" >> $ip_.ppr.txt
        sshpass -p "$pass_" ssh -o StrictHostKeyChecking=no $user_@$ip_ "sh log" >> $ip_.ppr.txt
        echo "==========" >> $ip_.ppr.txt
        echo "SHOW VERSION" >> $ip_.ppr.txt
        echo "==========" >> $ip_.ppr.txt
        sshpass -p "$pass_" ssh -o StrictHostKeyChecking=no $user_@$ip_ "sh ver" >> $ip_.ppr.txt
        echo -e "\033[0;32mОтключение от $ip_\033[0m"
        #Поиск названия оборудования
        name_=$(cat $ip_.ppr.txt | grep "hostname")
        name_words=($name_)
        #Переименование выходного файла
        mv $ip_.ppr.txt "/home/$USER@sgp.gazprom.ru/Документы/Данные со скрипта/PPR/${name_words[1]}.PPR.$date_.txt" 
    }

    function lets_go_exctract_ips {
        echo "$lpu_list" | while IFS= read -r line; do
            switches_list="$path_to_script$(echo "$line")"
            switches_=$(cat "$switches_list")
            #Строки проверяются на наличие названий вендоров и распределяются в соотвествующие списки. Потом эти списки проверяются на наличие IP-адресов и они сохраняются в отдельные переменные.
            cisco_list=$(echo "$switches_" | grep "Cisco")
            cisco_ips=$(echo "$cisco_list" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
            eltex_list=$(echo "$switches_" | grep "Элтекс")
            eltex_ips=$(echo "$eltex_list" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
            natex_list=$(echo "$switches_" | grep "Натекс")
            natex_ips=$(echo "$natex_list" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
            arlan_list=$(echo "$switches_" | grep "Арлан")
            arlan_ips=$(echo "$arlan_list" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
            #Если переменные не пустые, то выполняется команда к каждому IP-адресу из списка.
            if [ "$cisco_ips" != "" ]; then
                echo "$cisco_ips" | while IFS= read -r line; do
                    ip_=$line
                    lets_go_ppr
                    sleep 1
                done
            fi
            if [ "$eltex_ips" != "" ]; then
                echo "$eltex_ips" | while IFS= read -r line; do
                    ip_=$line
                    lets_go_ppr
                    sleep 1
                done
            fi
            if [ "$natex_ips" != "" ]; then
                echo "$natex_ips" | while IFS= read -r line; do
                    ip_=$line
                    lets_go_ppr
                    sleep 1
                done
            fi
            if [ "$arlan_ips" != "" ]; then
                echo "$arlan_ips" | while IFS= read -r line; do
                    ip_=$line
                    lets_go_ppr
                    sleep 1
                done  
            fi
        done
    }

    echo "IP-адреса из своего списка или из готовых?"
    echo "1. Свой"
    echo "2. Готовый"
    read list_
    if [ $list_ == "1" ]; then
        #Передача списка адресов в массив
        mapfile -t ips_ < "$ip_list"
        #Адреса из массива передаются в переменную
        for ip_ in "${ips_[@]}"; do
            #Проверка на правильность написания IP-адреса
            if [[ -z "$ip_" || "$ip_" == \#* ]]; then 
                continue
            fi
        lets_go_ppr
        done
    fi
    if [ $list_ == "2" ]; then
        cisco_list=()
        eltex_list=()
        natex_list=()
        arlan_list=()
        echo "Какой месяц нужен?"
        echo "1.  Январь"
        echo "2.  Февраль"
        echo "3.  Март"
        echo "4.  Апрель"     
        echo "5.  Май"
        echo "6.  Июнь"
        echo "7.  Июль"
        echo "8.  Август"
        echo "9.  Сентябрь"
        echo "10. Октябрь"
        echo "11. Ноябрь"
        echo "12. Декабрь"
        read sublist_
        if [ $sublist_ == "1" ]; then
            #Передаём IP-адреса в пременную
            lpu_list=$(cat "$path_to_script/Deus_networkus/Switch_PPR/January")
            lets_go_exctract_ips
        elif [ $sublist_ == "2" ]; then
            #Передаём IP-адреса в пременную
            lpu_list=$(cat "$path_to_script/Deus_networkus/Switch_PPR/February")
            lets_go_exctract_ips
        elif [ $sublist_ == "3" ]; then
            #Передаём IP-адреса в пременную
            lpu_list=$(cat "$path_to_script/Deus_networkus/Switch_PPR/March")
            lets_go_exctract_ips
        elif [ $sublist_ == "4" ]; then
            #Передаём IP-адреса в пременную
            lpu_list=$(cat "$path_to_script/Deus_networkus/Switch_PPR/April")
            lets_go_exctract_ips
        elif [ $sublist_ == "5" ]; then
            #Передаём IP-адреса в пременную
            lpu_list=$(cat "$path_to_script/Deus_networkus/Switch_PPR/May")
            lets_go_exctract_ips
        elif [ $sublist_ == "6" ]; then
            #Передаём IP-адреса в пременную
            lpu_list=$(cat "$path_to_script/Deus_networkus/Switch_PPR/June")
            lets_go_exctract_ips
        elif [ $sublist_ == "7" ]; then
            #Передаём IP-адреса в пременную
            lpu_list=$(cat "$path_to_script/Deus_networkus/Switch_PPR/July")
            lets_go_exctract_ips
        elif [ $sublist_ == "8" ]; then
            #Передаём IP-адреса в пременную
            lpu_list=$(cat "$path_to_script/Deus_networkus/Switch_PPR/August")
            lets_go_exctract_ips
        elif [ $sublist_ == "9" ]; then
            #Передаём IP-адреса в пременную
            lpu_list=$(cat "$path_to_script/Deus_networkus/Switch_PPR/September")
            lets_go_exctract_ips
        elif [ $sublist_ == "10" ]; then
             #Передаём IP-адреса в пременную
            lpu_list=$(cat "$path_to_script/Deus_networkus/Switch_PPR/October")
            lets_go_exctract_ips                          
        elif [ $sublist_ == "11" ]; then
            #Передаём IP-адреса в пременную
            lpu_list=$(cat "$path_to_script/Deus_networkus/Switch_PPR/November")
            lets_go_exctract_ips
        elif [ $sublist_ == "12" ]; then
            #Передаём IP-адреса в пременную
            lpu_list=$(cat "$path_to_script/Deus_networkus/Switch_PPR/December")
            lets_go_exctract_ips
        fi
    fi        
    echo -e "\033[32mЗадание выполнено\033[0m"
    echo " "
    echo " "
    echo " "
done
