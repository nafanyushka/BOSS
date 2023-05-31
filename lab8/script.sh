#!/bin/bash


systemServiceSearch(){
	read -p "Введите часть имени или имя службы: " serviceName
	systemctl list-unit-files "*$serviceName*" | less

	if [ $? -eq 1 ]	then
		echo -e "\nСлужба не найдена!\n" >&2
	else
		echo -e "\nУспешно!\n"
	fi

	read -p "Найти службу еще раз? (y/n): " confirm
	if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]
	then
		findServices
	else
		return 0
	fi
}

showSystemdProc(){
	ps xawf -eo pid,user,cgroup | grep ".service$"
}

serviceManagement(){
	IFS=$'\n' read -r -d '' -a arr < <(systemctl list-units --type=service | head -n-6 | tail -n+2 cut -c 3- | cut -d" " -f 1 && printf '\0')
	makelist arr "Номер сервиса: "
	num=$?
	echo "==========" $num
	if [ $num -eq 0 ]; then
		return
	fi
	service=${arr[num-1]}
	options2=(
		"Включить службу"
		"Отключить службу"
		"Запустить/перезапустить службу"
		"Остановить службу"
		"Вывести содержимое юнита службы"
		"Отредактировать юнит службы"
		"Выход"
	)
	select opt in "${options2[@]}"; do
		case $opt in
			"Включить службу")
				systemctl enable "$service"
				break
				;;
			"Отключить службу")
				systemctl disable "$service"
				break
				;;
			"Запустить/перезупустить службу")
				systemctl restart "$service"
				break
				;;
			"Остановить службу")
				systemctl stop "$service"
				break
				;;
			"Вывести содержимое юнита службы")
				less "$(systemctl status $service | head -n+2 | tail -n-1 | cut -f2 -d "(" | cut -f1 -d ";")"
				break
				;;
			"Отредактировать юнит службы")
				vim "$(systemctl status $service | head -n+2 | tail -n-1 | cut -f2 -d "(" | cut -f1 -d ";")"
				break
				;;
			"Выход")
				return
				;;
			*)
				echo "Ошибка! Неверный ввод" >&2
				break
		esac
	done
}

searchEvent(){
	read -p "Введите имя службы: " serv
	read -p "Введите степень важности: " priority
	read -p "Строка поиска: " request
	journalctl -p "$priority" -u "$service" -g "$request"
}

if [ "$EUID" -ne 0 ]; then
	echo "Only root may use this"
	exit
fi
if [[ "$2" != "" ]];
then
	echo "usage: ./script.sh [--help]" >&2
	exit
fi

case "$1" in
	--help)
		echo "Этот сценарий позволяет управлять системными службами и журналами"
		exit
		;;
esac

if [[ "$1" != "" ]];
then
	echo "usage: ./script.sh [--help]" >&2
	exit
fi

echo -e "\nПрограмма для управления системными службами и журналами.\n\nРазработчик: Баусов Вадим Романович, группа Б20-505\n"
echo -e "\nГлавное меню:\n"
PS3="> "

select answer in "Поиск системных служб" "Вывести список процессов и связанных с ними systemd служб" "Управление службами" "Поиск событий в журнале" "Выход"; do
	case $answer in 
		Выход)
		       	exit 0;;
		"Поиск системных служб")
			systemServiceSearch
			PS3="> "
			;;
		"Вывести список процессов и связанных с ними systemd служб")
			showSystemdProc
			PS3="> "
			;;
		"Управление службами")
			serviceManagement
			PS3="> "
			;;
		"Поиск событий в журнале")
			searchEvent	
			PS3="> "
			;;
		*)
			echo -e "\nОшибка! Такой опции не предусмотрено" >&2
			;;
	esac
	
	echo -e "--------------------------------------------------"
	echo -e "\nГлавное меню:\n"
	REPLY=
done