#!/bin/bash
# Управление процессами
# написать свою реализацию ps ax используя анализ /proc

# Функция вывода PID (идентификатор процесса)
PID_N()
  {
    cd /proc
    echo $PID 
  }

# Функция вывода STAT (состояние процесса)
STAT()
  {
    cd /proc
    if [ -f ${PID}/stat ]
      then
        cat ${PID}/stat | rev | awk '{printf $50}' | rev
      else
        echo 'н/у'
    fi
  }

# Функция вывода
TTY()
  {
  cd /proc  
  if [ -f ${PID}/stat ]
    then
      B=`cat ${PID}/stat | rev | awk '{printf $46}' | rev`;
      C=`bc <<< "obase=2;$B"`;
      D=`echo $C | rev`
      minor=${D:0:2}${D:4:3}
      major=${D:3:2}
      minor=`echo $minor | rev`
      major=`echo $major | rev`
      E=`echo $major$minor`
      F=`bc <<< "obase=10;ibase=2;$E"`;
      if [ $F = "0" ]; then
        echo '?';
      else
        echo tty$F;
      fi
    else
      echo 'н/у'
  fi
  }

# Функция вывода
TIME()
  {
  cd /proc
  if [ -f ${PID}/stat ]
    then
      cat ${PID}/stat | rev | awk '{print $36" "$37" "$38" "$39}' | rev | awk '{sum=$1+$2+$3+$4}END{print sum/100}' | awk '{("date +%M:%S -d @"$1)| getline $1}1'
    else
      echo 'н/у'
  fi
  }

# Функция вывода
COMMAND()
  { 
    cd /proc
    if [ -f ${PID}/stat ]
      then
        if grep -q '[/]' ${PID}/cmdline
          then
            cat ${PID}/cmdline
          else
            comper=`cat ${PID}/comm`
            echo "["$comper"]" 
        fi
      else
        echo 'н/у'
    fi  
  }

# Последовательный вывод параметров процесса в консоль
for PID in `ls -d /proc/* | egrep "^/proc/[0-9]+" | awk 'FS="/" {print $NF}' | sort -n`
  do  
    echo $(PID_N) $(TTY) $(STAT) $(TIME) $(COMMAND)      
  done