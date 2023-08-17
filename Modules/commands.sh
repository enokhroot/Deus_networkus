#!/bin/bash

cat << EOF
+-------------------------------------------------------------------------------+
|                               Модуль                                          |
|                   для массовой рассылки списка команд                         |
+-------------------------------------------------------------------------------+
EOF

while : #Запускается основной цикл
do
    echo "Добро пожаловать в модуль для управления оборудованием"
    echo "========================="
    echo "Введите имя пользователя:"
    read user_
    path_to_script=$1
    path_to_results= #Введите путь до папки, где хранится вывод данных
    #Скрыть ввод пароля 
    stty_orig=$(stty -g)
    stty -echo 
    read -p "Введите пароль: " pass_
    #Возврат нормального ввода
    stty "$stty_orig"
    #Функция для создания бэкапов
    function lets_go_backup {
        #Адреса из массива передаются в переменную
        for ip_ in "${ips_[@]}"; do
            #Проверка на правильность написания IP-адреса
            if [[ -z "$ip_" || "$ip_" == \#* ]]; then 
                continue
            fi
            echo -e "\033[0;32mПодключение к $ip_\033[0m"
            sshpass -p "$pass_" ssh -o StrictHostKeyChecking=no $user_@$ip_ "sh run" > "$path_to_results/Данные со скрипта/Backups/$ip_.config.txt"
            echo -e "\033[0;32mОтключение от $ip_\033[0m"
            #Поиск названия оборудования
            name_=$(cat " $path_to_results/Данные со скрипта/Backups/$ip_.config.txt" | grep "hostname")
            name_words=($name_)
            #Переименование выходного файла
            mv "$path_to_results/Данные со скрипта/Backups/$ip_.config.txt" "$path_to_results/Данные со скрипта/Backups/${name_words[1]}.txt" 
        done
    }
    #Функция для сохранения конфигурации Cisco, Eltex, Natex
    function lets_go_save_cisco_eltex_natex {
        echo -e "\033[0;32mПодключение к $ip_\033[0m"
        sshpass -p "$pass_" ssh -o StrictHostKeyChecking=no $user_@$ip_ "write memory"
        echo -e "\033[0;32mОтключение от $ip_\033[0m"
    }
    #Функция для сохранения конфигурации Arlan
    function lets_go_save_arlan {
        echo -e "\033[0;32mПодключение к $ip_\033[0m"
        sshpass -p "$pass_" ssh -o StrictHostKeyChecking=no $user_@$ip_ "copy running-config startup-config"
        echo -e "\033[0;32mОтключение от $ip_\033[0m"    
    }
    #Функция для передачи команд на коммутаторы
    function lets_go_command {
        #Команды из списка команд передаются по SSH
        echo -e "\033[0;32mПодключение к $ip_\033[0m"
        sshpass -p "$pass_" ssh -o StrictHostKeyChecking=no $user_@$ip_ < "$1/Deus_networkus/instructions_.txt"
        echo -e "\033[0;32mОтключение от $ip_\033[0m"
    }
    #Создаём список для IP-адресов
    ips_=()
    #Создаём переменные для ведоров
    cisco_list=()
    eltex_list=()
    natex_list=()
    arlan_list=()
    #Значение переменной считывается и выбирается соответствующее ему действие
    echo " "
    echo "Выберите действие, которое хотите сделать."
    echo "1. Сделать бэкап коммутатора на свой ПК."
    echo "2. Сохранить конфигурацию коммутатора."
    echo "3. Передать команды на коммутатор."
    read command_
    #Цикл для выбора объектов для бэкапа
    if [ $command_ == "1" ]; then
        echo "IP-адреса из своего списка или из готовых?"
        echo "1. Свой"
        echo "2. Готовый"
        read list_
        if [ $list_ == "1" ]; then
            echo "Список уже готов или Вы хотите создать его прямо сейчас?"
            echo "1. Готов"
            echo "2. Сделаю сейчас"
            read ready_            
            if [ $ready_ == "1" ]; then
                #Передача списка адресов в переменную
                ip_="$1/Deus_networkus/ip_.txt"
                #Передача списка адресов в массив
                mapfile -t ips_ < "$ip_"
                lets_go_backup
            fi
            if [ $ready_ == "2" ]; then
                #Создаём переменную, в которую сохраним путь к файлу с IP-адресами
                output_file="$1/Deus_networkus/ip_.txt"
                #Очистим файл
                > "$output_file"
                echo "Введите IP-адреса. Для завершения используйте Ctrl+D"
                #Считываем данные и передаём их в файл
                while read -p "IP адрес: " ip_address; do
                    echo "$ip_address" >> "$output_file"
                done
                echo "Ввод завершён. IP-адреса сохранены."
                #Передача списка адресов в переменную
                ip_="$1/Deus_networkus/ip_.txt"
                #Передача списка адресов в массив
                mapfile -t ips_ < "$ip_"
                lets_go_backup
            fi
        fi
        if [ $list_ == "2" ]; then
            echo " "
            echo "Какое оборудование Вам нужно? "
            echo "============================="
            #Считываются папки, в которых содержатся папки с площадками и выводятся списком, обозначая сегменты оборудования.
            list_segments_="$(ls "$1/Deus_networkus/Lists_of_switches/")"
            #Сортируем список в порядке возрастания
            sort_list_segments_=$(echo -e "$list_segments_" | sort -n)
            #Выводится список сегментов, отсортированный по числам
            echo "$sort_list_segments_"
            #Выбирается сегмент
            read segment_
            #Запускается скрипт для вывода списка оборудования из папок
            source "$path_to_script/Deus_networkus/Modules/choose_your_equipments.sh"
            #Получаем строки из файла и находим IP-адреса
            ips_+=$(grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" "$list_switches_")
            #Передаём адреса в файл и в массив. Потом это нужно упростить и сделать напрямую, без файла.
            echo "$ips_" > "$1/Deus_networkus/ip_.txt"
            mapfile -t ips_ < "$1/Deus_networkus/ip_.txt"
            lets_go_backup
        fi
    fi
    if [ $command_ == "2" ]; then
        echo "IP-адреса из своего списка или из готовых?"
        echo "1. Свой"
        echo "2. Готовый"
        read list_
        if [ $list_ == "1" ]; then
            #Запрос вендора
            echo "Выберите вендора:"
            echo "1. Cisco, Eltex, Natex"
            echo "2. Arlan"
            read vendor_
            echo "Список уже готов или Вы хотите создать его прямо сейчас?"
            echo "1. Готов"
            echo "2. Сделаю сейчас"
            read ready_            
            if [ $ready_ == "1" ]; then
                #Передача списка адресов в переменную
                ip_list="$1/Deus_networkus/ip_.txt"
                #Передача списка адресов в массив
                mapfile -t ips_ < "$ip_list"
                #Адреса из массива передаются в переменную и согласно вендора запускается необходимая функция
                for ip_ in "${ips_[@]}"; do
                    #Проверка на правильность написания IP-адреса
                    if [[ -z "$ip_" || "$ip_" == \#* ]]; then
                        continue
                    fi
                    if [ $vendor_ == "1" ]; then
                        lets_go_save_cisco_eltex_natex
                        sleep 1
                    elif [ $vendor_ == "2" ]; then
                        lets_go_save_arlan
                        sleep 1             
                    fi
                done
            fi
            if [ $ready_ == "2" ]; then
                #Создаём переменную, в которую сохраним путь к файлу с IP-адресами
                output_file="$1/Deus_networkus/ip_.txt"
                #Очистим файл
                > "$output_file"
                echo "Введите IP-адреса. Для завершения используйте Ctrl+D"
                #Считываем данные и передаём их в файл
                while read -p "IP адрес: " ip_address; do
                    echo "$ip_address" >> "$output_file"
                done
                echo "Ввод завершён. IP-адреса сохранены."
                #Передача списка адресов в переменную
                ip_list="$1/Deus_networkus/ip_.txt"
                #Передача списка адресов в массив
                mapfile -t ips_ < "$ip_list"
                #Адреса из массива передаются в переменную и согласно вендора запускается необходимая функция
                for ip_ in "${ips_[@]}"; do
                    #Проверка на правильность написания IP-адреса
                    if [[ -z "$ip_" || "$ip_" == \#* ]]; then
                        continue
                    fi
                    if [ $vendor_ == "1" ]; then
                        lets_go_save_cisco_eltex_natex
                        sleep 1
                    elif [ $vendor_ == "2" ]; then
                        lets_go_save_arlan
                        sleep 1             
                    fi
                done
            fi
        fi
        if [ $list_ == "2" ]; then
            echo " "
            echo "Какое оборудование Вам нужно? "
            echo "============================="
            #Считываются папки, в которых содержатся папки с площадками и выводятся списком, обозначая сегменты оборудования.
            list_segments_="$(ls "$1/Deus_networkus/Lists_of_switches/")"
            #Сортируем список в порядке возрастания
            sort_list_segments_=$(echo -e "$list_segments_" | sort -n)
            #Выводится список сегментов, отсортированный по числам
            echo "$sort_list_segments_"
            #Выбирается сегмент
            read segment_
            #Запускается скрипт для вывода списка оборудования из папок
            source "$path_to_script/Deus_networkus/Modules/choose_your_equipments.sh"
            #Содержимое файла передаётся в переменную
            switches_=$(cat "$list_switches_")
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
                    lets_go_save_cisco_eltex_natex
                    sleep 1
                done
            fi
            if [ "$eltex_ips" != "" ]; then
                echo "$eltex_ips" | while IFS= read -r line; do
                    ip_=$line
                    lets_go_save_cisco_eltex_natex
                    sleep 1
                done
            fi
            if [ "$natex_ips" != "" ]; then
                echo "$natex_ips" | while IFS= read -r line; do
                    ip_=$line
                    lets_go_save_cisco_eltex_natex
                    sleep 1
                done
            fi
            if [ "$arlan_ips" != "" ]; then
                echo "$arlan_ips" | while IFS= read -r line; do
                    ip_=$line
                    lets_go_save_arlan
                    sleep 1
                done  
            fi

        fi   
    fi
    if [ $command_ == "3" ]; then
        echo "IP-адреса из своего списка или из готовых?"
        echo "1. Свой"
        echo "2. Готовый"
        read list_
        if [ $list_ == "1" ]; then
            echo "Список уже готов или Вы хотите создать его прямо сейчас?"
            echo "1. Готов"
            echo "2. Сделаю сейчас"
            read ready_            
            if [ $ready_ == "1" ]; then
                echo "Команды уже записаны в файл или записать сейчас?"
                echo "1. Уже записаны"
                echo "2. Записать сейчас"
                read commands_ready
                if [ $commands_ready == "1" ]; then
                    #Передача списка адресов в переменную
                    ip_list="$1/Deus_networkus/ip_.txt"
                    #Передача списка адресов в массив
                    mapfile -t ips_ < "$ip_list"
                    #Адреса из массива передаются в переменную
                    for ip_ in "${ips_[@]}"; do
                    #Проверка на правильность написания IP-адреса
                        if [[ -z "$ip_" || "$ip_" == \#* ]]; then 
                            continue
                        fi
                        lets_go_command
                        sleep 1
                    done
                fi
                if [ $commands_ready == "2" ]; then
                    #Создаём переменную, в которую сохраним путь к файлу с IP-адресами
                    output_commands_file="$1/Deus_networkus/instructions_.txt"
                    #Очистим файл
                    > "$output_commands_file"
                    echo "Введите команды. Для завершения используйте Ctrl+D"
                    #Считываем данные и передаём их в файл
                    while read -p "Команда: " command_to_file; do
                        echo "$command_to_file" >> "$output_commands_file"
                    done
                    echo "Ввод завершён. Команды сохранены."
                    #Передача списка адресов в переменную
                    ip_list="$1/Deus_networkus/ip_.txt"
                    #Передача списка адресов в массив
                    mapfile -t ips_ < "$ip_list"
                    #Адреса из массива передаются в переменную
                    for ip_ in "${ips_[@]}"; do
                    #Проверка на правильность написания IP-адреса
                        if [[ -z "$ip_" || "$ip_" == \#* ]]; then 
                            continue
                        fi
                        lets_go_command
                        sleep 1
                    done
                fi                                             
            fi
            if [ $ready_ == "2" ]; then
                #Создаём переменную, в которую сохраним путь к файлу с IP-адресами
                output_file="$1/Deus_networkus/ip_.txt"
                #Очистим файл
                > "$output_file"
                echo "Введите IP-адреса. Для завершения используйте Ctrl+D"
                #Считываем данные и передаём их в файл
                while read -p "IP адрес: " ip_address; do
                    echo "$ip_address" >> "$output_file"
                done
                echo "Ввод завершён. IP-адреса сохранены."
                echo "Команды уже записаны в файл или записать сейчас?"
                echo "1. Уже записаны"
                echo "2. Записать сейчас"
                read commands_ready
                if [ $commands_ready == "1" ]; then
                    #Передача списка адресов в переменную
                    ip_list="$output_file"
                    #Передача списка адресов в массив
                    mapfile -t ips_ < "$ip_list"
                    #Адреса из массива передаются в переменную
                    for ip_ in "${ips_[@]}"; do
                    #Проверка на правильность написания IP-адреса
                        if [[ -z "$ip_" || "$ip_" == \#* ]]; then 
                            continue
                        fi
                        lets_go_command
                        sleep 1
                    done
                fi
                if [ $commands_ready == "2" ]; then
                    #Создаём переменную, в которую сохраним путь к файлу с IP-адресами
                    output_commands_file="$1/Deus_networkus/instructions_.txt"
                    #Очистим файл
                    > "$output_commands_file"
                    echo "Введите команды. Для завершения используйте Ctrl+D"
                    #Считываем данные и передаём их в файл
                    while read -p "Команда: " command_to_file; do
                        echo "$command_to_file" >> "$output_commands_file"
                    done
                    echo "Ввод завершён. Команды сохранены."
                    #Передача списка адресов в переменную
                    ip_list="$1/Deus_networkus/ip_.txt"
                    #Передача списка адресов в массив
                    mapfile -t ips_ < "$ip_list"
                    #Адреса из массива передаются в переменную
                    for ip_ in "${ips_[@]}"; do
                    #Проверка на правильность написания IP-адреса
                        if [[ -z "$ip_" || "$ip_" == \#* ]]; then 
                            continue
                        fi
                        lets_go_command
                        sleep 1
                    done
                fi                                              
            fi
        fi
        if [ $list_ == "2" ]; then
            echo " "
            echo "Какое оборудование Вам нужно? "
            echo "============================="
            #Считываются папки, в которых содержатся папки с площадками и выводятся списком, обозначая сегменты оборудования.
            list_segments_="$(ls "$1/Deus_networkus/Lists_of_switches/")"
            #Сортируем список в порядке возрастания
            sort_list_segments_=$(echo -e "$list_segments_" | sort -n)
            #Выводится список сегментов, отсортированный по числам
            echo "$sort_list_segments_"
            #Выбирается сегмент
            read segment_
            #Запускается скрипт для вывода списка оборудования из папок
            source "$path_to_script/Deus_networkus/Modules/choose_your_equipments.sh"
            #Содержимое файла передаётся в переменную
            switches_=$(cat "$list_switches_")
            #Строки проверяются на наличие названий вендоров и распределяются в соотвествующие списки. Потом эти списки проверяются на наличие IP-адресов и они сохраняются в отдельные переменные.
            cisco_list=$(echo "$switches_" | grep "Cisco")
            cisco_ips=$(echo "$cisco_list" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
            eltex_list=$(echo "$switches_" | grep "Элтекс")
            eltex_ips=$(echo "$eltex_list" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
            natex_list=$(echo "$switches_" | grep "Натекс")
            natex_ips=$(echo "$natex_list" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
            arlan_list=$(echo "$switches_" | grep "Арлан")
            arlan_ips=$(echo "$arlan_list" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
            echo "Команды уже записаны в файл или записать сейчас?"
            echo "1. Уже записаны"
            echo "2. Записать сейчас"
            read commands_ready
            if [ $commands_ready == "1" ]; then
                #Если переменные не пустые, то выполняется команда к каждому IP-адресу из списка.
                if [ "$cisco_ips" != "" ]; then
                    echo "$cisco_ips" | while IFS= read -r line; do
                        ip_=$line
                        lets_go_command $1
                        sleep 1
                    done
                fi
                if [ "$eltex_ips" != "" ]; then
                    echo "$eltex_ips" | while IFS= read -r line; do
                        ip_=$line
                        lets_go_command $1
                        sleep 1
                    done
                fi
                if [ "$natex_ips" != "" ]; then
                    echo "$natex_ips" | while IFS= read -r line; do
                        ip_=$line
                        lets_go_command $1
                        sleep 1
                    done
                fi
                if [ "$arlan_ips" != "" ]; then
                    echo "$arlan_ips" | while IFS= read -r line; do
                        ip_=$line
                        lets_go_command $1
                        sleep 1
                    done  
                fi
            fi
            if [ $commands_ready == "2" ]; then
                #Создаём переменную, в которую сохраним путь к файлу с IP-адресами
                output_commands_file="$1/Deus_networkus/instructions_.txt"
                #Очистим файл
                > "$output_commands_file"
                echo "Введите команды. Для завершения используйте Ctrl+D"
                #Считываем данные и передаём их в файл
                while read -p "Команда: " command_to_file; do
                    echo "$command_to_file" >> "$output_commands_file"
                done
                echo "Ввод завершён. Команды сохранены."
                #Если переменные не пустые, то выполняется команда к каждому IP-адресу из списка.
                if [ "$cisco_ips" != "" ]; then
                    echo "$cisco_ips" | while IFS= read -r line; do
                        ip_=$line
                        lets_go_command $1
                        sleep 1
                    done
                fi
                if [ "$eltex_ips" != "" ]; then
                    echo "$eltex_ips" | while IFS= read -r line; do
                        ip_=$line
                        lets_go_command $1
                        sleep 1
                    done
                fi
                if [ "$natex_ips" != "" ]; then
                    echo "$natex_ips" | while IFS= read -r line; do
                        ip_=$line
                        lets_go_command $1
                        sleep 1
                    done
                fi
                if [ "$arlan_ips" != "" ]; then
                    echo "$arlan_ips" | while IFS= read -r line; do
                        ip_=$line
                        lets_go_command $1
                        sleep 1
                    done  
                fi
            fi
        fi        
    fi
    echo -e "\033[32mЗадание выполнено!\033[0m"
    echo " "
done