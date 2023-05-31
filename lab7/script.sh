#!/bin/bash

function showFSTable() {
  echo -e "\n"
  df -x sys -x proc -x tmpfs -x devtmpfs -H --output=target,source,fstype,size
  echo -e "\n"
}

function mountFS() {
  read -p "Введите путь до файла или устройства: " path

  if [ ! -b $path ] && [ ! -f $path ] then
    echo "Указан неправильный путь!" >&2
    return 1 
  fi

  read -p "Введите путь монтирования: " mountPath

  if [ ! -e $mountPath ]
  then
    mkdir $mountPath
  fi

  if [ -d $mountPath ]
  then
    if [ ! -z "$(ls $mountPath)" ]
    then
      echo "Директория не пустая!" >&2
      return 1
    fi
  else
    echo "Это не директория!" >&2
  fi

  if [ -f $path ] 
  then
    device=$(losetup --find --show $path)
    mkfs -t ext4 $device
    mount $device $mountPath
  else
    mount $path $mountPath
  fi
  if [ $? -ne 0 ]
  then
    echo "Не удалось монтировать" >&2
    return 1
  else
    echo "Удалось монтировать" >&2
  fi
  mount | grep $mountPath
  return 0
}

function table() {
  local -n choos=$1
  choos+=("Помощь" "Выход")
  while true 
  do
    select opt in "${choos[@]}"
    do
      case $opt in
        "Помощь") 
          echo -e "Выберите номер" 
          break;;
        "Выход")
          return 0
          ;;
        *)
          if [ ! -z $opt ]
          then
            return $REPLY
          else
            echo "Номер должен быть из списка"
            break
          fi
      esac
    done
  done
}

function unMountFS() {
  readarray -t menu < <(df -Th -x procfs -x tmpfs -x devtmpfs -x sysfs | tail -n +6 | cut -d ' ' -f 1)
  menu+=(Помощь Назад)
  PS3="Выберите файловую систему, которую хотите отмонтировать или путь до неё > "
  select ans in "${menu[@]}"; do
    case $ans in 
      Помощь)
        echo -e "\nКакую файловую систему отмонтировать\n"
        ;;
      Назад)
        break
        ;;
      *)
        if [[ -z $ans ]]; then 
          if [[ " ${menu[*]} " =~ " ${REPLY} " ]]; then 
            umount $REPLY
            losetup --detach $REPLY
            break
          fi
          echo -e "Ошибка! Некорректный ввод\n" >&2
          break
        else
          umount $ans
          losetup --detach $ans
          break
        fi
        ;;
    esac
  done
}

function changeParams() {
  IFS=$'\n' read -r -d '' -a array < <(df -x proc -x sys -x devtmpfs -x tmpfs --output=target | tail -n+2 && echo -e '\0')
  echo -e "Введите цифру, которую хотите изменить\n"
  table array
  ret=$?
  if [ $ret -ne 0 ]
  then
    path=${array[ret-1]}
  else
    echo -e "Ошибка" >&2
    return
  fi
  echo -e "Выберите параметры файловой системы: \n1. Read only\n2. Read and Write\n.3 Exit\n\n"
  read -p "> " input
  case $input in 
    1)
      mount -o remount,ro $path;;
    2)
      mount -o remount,rw $path;;
    3)
      exit;;
    *)
      echo "Error"
      return 1;;
  esac
}

function showFsParams() {
  read -p "Введите путь до файловой системы: " path

  if [ ! -z $path ]
  then
    mount | grep $path
  else
     IFS=$'\n' read -r -d '' -a array < <(df -x proc -x sys -x devtmpfs -x tmpfs --output=target | tail -n+2 && echo -e '\0')
     table array
     ret=$?
     if [ $ret -eq 0 ]
     then
       return 0
     fi
     mount | grep ${array[ret-1]}
     if [ $? -ne 0 ]
     then
       echo 'Ошибка' >&2
     else
       echo 'Успешно'
     fi
  fi

}

function showExtInfo() {
readarray -t menu3 < <(mount | grep -e "ext.")
  menu3+=(Помощь Назад)
  PS3="Введите номер файловой системы, информацию о которой хотите увидеть > "
  select ans3 in "${menu3[@]}"; do
    case $ans3 in 
      Помощь)
        echo -e "\nВ этом разделе вы можете увидеть информацию о выбранной файловой системе\n"
        ;;
			Назад)
				break
				;;
			*)
				if [[ -z $ans3 ]]; then 
					echo -e "Некорректный ввод\n" >&2
					break
				else
					tune2fs -l $(echo "$ans3" | cut -d ' ' -f 1)
				fi
				break
				;;
		esac
	done

}


if [ "$EUID" -ne 0 ]
  then echo "Ошибка! У вас нет прав администратора."
  exit
fi

if [ "$1" = "--help" ]
then
  echo -e "С помощью данной программы вы можете управлять файловой системой.\nРазработчик: Баусов Вадим Романович, группа Б20-505"
  exit
fi


PS3='> '
options=("Вывести таблицу файловых систем" "Монтировать файловую систему" "Отмонтировать файловую систему" "Изменить параметры монтирования примонтированной файловой системы" "Вывести параметры монтирования примонтированной файловой системы" "Вывести детальную информацию о файловой системе ext*" "Выход")
while true
do
  select opt in "${options[@]}"
  do
  case $opt in
    "Вывести таблицу файловых систем") 
      showFSTable 
      break;;
    "Монтировать файловую систему") 
      mountFS 
      break;;
    "Отмонтировать файловую систему") 
      unMountFS 
      break;;
    "Изменить параметры монтирования примонтированной файловой системы") 
      changeParams 
      break;;
    "Вывести параметры монтирования примонтированной файловой системы") 
      showFsParams
      break;;
    "Вывести детальную информацию о файловой системе ext*") 
      showExtInfo
      break;;
    "Выход") exit;;
    *) echo "Нет такой опции";;
  esac

  done
done