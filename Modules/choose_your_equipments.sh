#!/bin/bash

selected_segment_=$(echo "$sort_list_segments_" | sed -n "${segment_}p")
#Считываются папки, в которых содержатся файлы с IP-адресами коммутаторов и выводятся списком, обозначая сегменты оборудования.
list_lpu_="$(ls "$path_to_script/Deus_networkus/Lists_of_switches/$selected_segment_/")"
#Сортируем список в порядке возрастания
sort_list_lpu_=$(echo -e "$list_lpu_" | sort -n)
#Выводится список ЛПУ, отсортированный по числам
echo "$sort_list_lpu_"
echo "============================="
read lpu_
if [[ -z "$lpu_" ]]; then
    continue
fi
selected_lpu_=$(echo "$sort_list_lpu_" | sed -n "${lpu_}p")
#Считываются файлы, соответствующие местам установки, с IP-адресами оборудования
list_places_="$(ls "$path_to_script/Deus_networkus/Lists_of_switches/$selected_segment_/$selected_lpu_/")"
#Сортируем список в порядке возрастания
sort_list_places_=$(echo -e "$list_places_" | sort -n)
echo "$sort_list_places_"
echo "============================="
read place_
if [[ -z "$place_" ]]; then
    continue
fi
selected_place_=$(echo "$sort_list_places_" | sed -n "${place_}p")
list_switches_=$(ls "$path_to_script/Deus_networkus/Lists_of_switches/$selected_segment_/$selected_lpu_/$selected_place_")
export list_switches_