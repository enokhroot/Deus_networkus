#! /bin/bash

cat << EOF
 
                      ██████╗░███████╗██╗░░░██╗░██████╗
                      ██╔══██╗██╔════╝██║░░░██║██╔════╝
                      ██║░░██║█████╗░░██║░░░██║╚█████╗░
                      ██║░░██║██╔══╝░░██║░░░██║░╚═══██╗
                      ██████╔╝███████╗╚██████╔╝██████╔╝
                      ╚═════╝░╚══════╝░╚═════╝░╚═════╝░

███╗░░██╗███████╗████████╗░██╗░░░░░░░██╗░█████╗░██████╗░██╗░░██╗██╗░░░██╗░██████╗
████╗░██║██╔════╝╚══██╔══╝░██║░░██╗░░██║██╔══██╗██╔══██╗██║░██╔╝██║░░░██║██╔════╝
██╔██╗██║█████╗░░░░░██║░░░░╚██╗████╗██╔╝██║░░██║██████╔╝█████═╝░██║░░░██║╚█████╗░
██║╚████║██╔══╝░░░░░██║░░░░░████╔═████║░██║░░██║██╔══██╗██╔═██╗░██║░░░██║░╚═══██╗
██║░╚███║███████╗░░░██║░░░░░╚██╔╝░╚██╔╝░╚█████╔╝██║░░██║██║░╚██╗╚██████╔╝██████╔╝
╚═╝░░╚══╝╚══════╝░░░╚═╝░░░░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝░╚═════╝░╚═════╝░

+-------------------------------------------------------------------------------+
|                                Скрипт                                         |
|                  для подключения к сетевому оборудованию                      |
+-------------------------------------------------------------------------------+
EOF
# Устанавливаем список необхожимого софта и список для записи того чего у нас ещё нет
soft_=("telnet" "xpra" "ssh" "sshpass")
need_soft_=()
# Проверяем наличие установленных программ по списку и добавлением необходимого в пустой список.
# Если программа установлена, но возле неё отображается галочка, если нет - крестик.
for program in "${soft_[@]}"
do
    if [ -x "$(command -v $program)" ]; then
        echo -e "$program \033[32m✔\033[0m"
    else
        echo -e "$program \033[31m✘\033[0m"
        need_soft_+="$program"
        need_soft_+=" "
    fi
done
#Функция для ввода логина и пароля от оборудования (Tacacs или локальный)
function lets_go_pass {
    echo "Введите имя пользователя:"
    read user_
    #Скрыть ввод пароля 
    stty_orig=$(stty -g)
    stty -echo 
    read -p "Введите пароль:" pass_
    #Возврат нормального ввода
    stty "$stty_orig"
}
#Указывается путь до папки со скриптами и до папки с хранением вывода
path_to_script="/home/$USER/Документы/Scripts"
path_to_date="/home/$USER/Документы"
#Проверяем существуют ли папки для сохранения файлов с данными по работе скриптов
if [ -d "$path_to_date/Данные со скрипта" ] && [ -d "$path_to_date/Данные со скрипта/Backups" ] && [ -d "$path_to_date/Данные со скрипта/PPR" ]; then
    echo "Все необходимые папки для сохранения данных имеются"
else
    if ! [ -d "$path_to_date/Данные со скрипта" ]; then
        mkdir "$path_to_date/Данные со скрипта"
    fi
    if ! [ -d "$path_to_date/Данные со скрипта/Badckups" ]; then    
        mkdir "$path_to_date/Данные со скрипта/Backups"
    fi
    if ! [ -d "$path_to_date/Данные со скрипта/PPR" ]; then
        mkdir "$path_to_date/Данные со скрипта/PPR"
    fi
    echo "Необходимые папки для работы скрипта созданы"
fi
#Указывается название терминала в системе
your_terminal=mate-terminal
echo "============================="
# Если весь необходимый софт установлен, то запускается основной цикл
if [[ ${#need_soft_[@]} == 0 ]]; then
    lets_go_pass

    #Передаём в переменные списки с IP-адресами, чьи протоколы подключения отличаются от SSH
    telnet_cisco_=$(cat "$path_to_script/Deus_networkus/telnet_cisco")
    telnet_natex_=$(cat "$path_to_script/Deus_networkus/telnet_natex")
    WEB_=$(cat "$path_to_script/Deus_networkus/WEB")

    #Разбиваем IP-адреса из файлов на переменные
    IFS=$'\n' read -ra telnet_cisco_array <<< "$telnet_cisco_"
    IFS=$'\n' read -ra telnet_natex_array <<< "$telnet_natex_"
    IFS=$'\n' read -ra WEB_array <<< "$WEB_"

    #Вводим флаг для проверки наличия IP-адресов в списках
    found_=false

    #Функция для вызова коммутатора
    function lets_go_connect {
        #Считывается аргумент, передаваемый при вызове функции, соответствующий порядковому номеру коммутатора
        line_number="$1"
        #Из списка IP-адресов выбирается нужный, согласно принятому аргументу
        selected_ip=$(echo "$ips_" | sed -n "${line_number}p")
        #Через терминал запускается сеанс mate-terminal, имя пользователя и пароль передаются из переменных, подтверждение подключения к новому хосту проводится автоматически.
        #Проверяются некоторые IP, которые не имеют SSH, и подключаются согласно доступным средствам.
        for item_ in "${telnet_cisco_array[@]}"; do
            if [[ "$item_" == "$selected_ip" ]]; then
                found_=true
                $your_terminal -e "$path_to_script/Deus_networkus/Modules/telnet_connect_cisco.sh "$selected_ip" "$user_" "$pass_""
                break
            fi
        done
        if ! $found_; then
            for item_ in "${telnet_natex_array[@]}"; do
                if [[ "$item_" == "$selected_ip" ]]; then
                    found_=true
                    $your_terminal -e "$path_to_script/Deus_networkus/Modules/telnet_connect_natex.sh "$selected_ip" "$user_" "$pass_""
                    break
                fi
            done
        fi
        if ! $found_; then
            for item_ in "${WEB_array[@]}"; do
                if [[ "$item_" == "$selected_ip" ]]; then
                    found_=true
                    $your_terminal -e "firefox "$selected_ip""
                    break
                fi
            done
        fi
        if ! $found_; then
            $your_terminal  -e "sshpass -p "$pass_" ssh -o StrictHostKeyChecking=no $user_@$selected_ip"
        fi

        found_=false
    }

    while : #Запускается цикл вывода меню
    do
        echo " "
        echo "============================="
        echo "Какое оборудование Вам нужно? "
        echo "============================="
        #Считываются папки, в которых содержатся папки с площадками и выводятся списком, обозначая сегменты оборудования.
        list_segments_="$(ls "$path_to_script/Deus_networkus/Lists_of_switches/")"
        #Сортируем список в порядке возрастания
        sort_list_segments_=$(echo -e "$list_segments_" | sort -n)
        #Выводится список сегментов, отсортированный по числам
        echo "$sort_list_segments_"
        echo "============================="
        echo "Дополнительные модули:"
        echo "============================="
        echo "Введите 'commands' для передачи целого списка команд на разное оборудование."
        echo "Введите 'ppr' для проведения ППР коммутаторов."
        echo "Введите 'xpra' для настройки оборудования через подключение к удалённому ПК."
        echo "Введите 'tftp', чтобы поднять TFTP-сервер на 10.32.5.142"
        echo "Введите 'test', чтобы протестировать связь до узла"
        echo "Введите 'pass', чтобы обновить логин и пароль введёные ранее в скрипт"
        echo "Введите 'update' для обновления скрипта."        
        #Выбирается сегмент
        read segment_
        #Проверка на пустой ввод
        if [[ -z "$segment_" ]]; then
            continue
        #Запуск модуля для передачи команд на оборудование
        elif [[ "$segment_" == "commands" ]]; then
            $your_terminal -e "$path_to_script/Deus_networkus/Modules/commands.sh $path_to_script"
            continue
        #Запуск модуля для проведения ППР
        elif [[ "$segment_" == "ppr" ]]; then
            $your_terminal -e "$path_to_script/Deus_networkus/Modules/ppr.sh $path_to_script"
            continue
        #Запуск модуля для обновления скрипта
        elif [[ "$segment_" == "update" ]]; then
            $your_terminal -e "$path_to_script/Deus_networkus/Modules/update.sh $path_to_script"
            sleep 1
            echo -e "\033[32mОбновление завершено\033[0m"
            exec "$0"
        #Запуск модуля для обновления логина и пароля
        elif [[ "$segment_" == "pass" ]]; then
            lets_go_pass
            continue
        #Подключение к оборудованию через удалённый ПК, с установленным Putty. Пользователь должен иметь root-права для подключения к Serial-порту.
        elif [[ "$segment_" == "xpra" ]]; then
            echo "Введите IP-адрес ПК к которому нужно подключиться"
            read ip_
            echo "Введите имя пользователя на сервере"
            read username_
            xpra start ssh://$username_@$ip_ --start=putty
            continue
        elif [[ "$segment_" == "tftp" ]]; then
            echo "Введите имя пользователя на сервере 10.32.5.142"
            read username_
            echo "Какая подсеть Вам нужна? "
            echo "============================="
            echo "1. АСУ ПХД"
            echo "2. АСУ ТП и КПТМ"
            read net_
            #Запускается скрипт для одной из подсетей. Файлы хранятсяя в папке /home/tftp
            if [ $net_ == "1" ]; then 
                ssh -t $username_@10.32.5.142 "sudo python2 tftpgui/tftpgui.py tftpgui/tftpgui_phd.cfg --nogui"
            elif [ $net_ == "2" ]; then
                ssh -t $username_@10.32.5.142 "sudo python2 tftpgui/tftpgui.py tftpgui/tftpgui_tp.cfg --nogui"
            fi
            continue
        elif [[ "$segment_" == "test" ]]; then
            echo "Введите IP-адрес соединение до которого нужно проверить"
            read ip_
            $your_terminal -e "$path_to_script/Deus_networkus/Modules/network_test.sh $ip_"
            continue
        fi
        #Запускается скрипт для вывода списка оборудования из папок
        source "$path_to_script/Deus_networkus/Modules/choose_your_equipments.sh"
        #Пока не будет нажат Enter, будет появляться список оборудования
        while :
        do
            #Выводим список оборудования
            cat "$list_switches_"
            #Составляем список адресов, содержащихся в файле
            ips_=$(grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" "$list_switches_")
            #Считывается коммутатор
            read switch_
            if [[ -z "$switch_" ]]; then
                break
            fi
            lets_go_connect "$switch_"
        done
        clear #По нажатию клавиши Enter очищается экран и цикл идёт на новую итерацию
    done
# Если какого-то софта не хватает, то появляется список того, что нужно установить
else
    echo -e "\033[31mНеобходимо установить следующий софт:\033[0m"
    echo ${need_soft_}
    read
fi