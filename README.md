# Управление процессами.

## Собственная реализация (скрипт) команды `ps ax` используя анализ `/proc`

### Мануал по скрипту.

Пример вывода команды `ps ax` на апримере процесса с идентификатором `997`

```
PID  TTY  STAT   TIME   COMMAND
...
997   ?   Ss     0:00   /usr/sbin/sshd -D
```
где:

PID - идентификатор процесса;

TTY - терминал, из которого запущен процесс;

STAT - состояние процесса;

TIME - общее время процессора, затраченное на выполнение процессора;

COMMAND - команда запуска процессора.

Скрипт представляет собой набор функций, которые путем обработки файлов и подкаталогов файловой системы `/proc` собирают параметры каждого процесса, после чего осуществляется последовательный вывод.

### Вывод PID (идентификатор процесса)

Подкаталог `/proc/<PID>/` и есть `PID` самого процесса. Обходим `/proc`, выбираем подкаталоги название, которых есть цифра или число, сортируем получившийся список.

```
ls -d /proc/* | egrep "^/proc/[0-9]+" | awk 'FS="/" {print $NF}' | sort -n
```
Функция вывода PID

```
echo $PID
```

### Вывод TTY (идентификатор терминала, из которого запущен процесс)

Мануал утверждает:

```
Руководство программиста Linux PROC
...
Управляющий терминал процесса.
(minor номер устройства содержится в комбинации битов с 31 по 20 и с 7 по 0;
major номер устройства находится в битах с 15 по 8.)
...
```

Параметр `TTY` находится на 7 позиции в файле `/proc/<PID>/stat`. Но така как при выборе функцией `awk`  могут возникнуть проблемы из-за символов содержащихся во втором поле, производим выборку `46` поля с конца.

```
cat ${PID}/stat | rev | awk '{printf $46}' | rev
```
Сам алгоритм преобразования поля 

```
<PID> --> (Decimal to Binary) --> 10000000010 --> 1 0 0 0 0 0 0 0 0 1 0 --┐
                                                                         ╎
позиции бит      (31)           (20)     (15)     (8)(7)      (0)        ╎ 
                  ↓              ↓        ↓        ↓  ↓        ↓         ╎ 
0001  0000  0000  0000  0000  0000  0000  0000  0000  0001  0000         ╎ 
   1     0     0     0     0     0     0     0     0     1     0  <------┘ 
                  ╎                    ╎  └--MAJOR-┘  ╎        ╎
                  └---------┬----------┘     (15..8)  └----┬---┘
                            ╎                              ╎
                            ╎                              ╎
                            └----------------MINOR---------┘
                                         (31..20, 7..0) 
                            
MINOR 00000010 --> (Binary to Decimal) --> 2 ---┐
                                                ╎
                                                |--> ("Major" concat "Minor") --> 02 => tty2
                                                ╎
MAJOR 00 --> (Binary to Decimal) --> 0 ---------┘ 


("Major" concat "Minor") --> 02 => tty2
```

и его программную реализацию взял из интернета (нагуглил).

### Вывод STAT (состояние процесса)

Параметр `STAT` находится в `7` поле в файла `/proc/<PID>/stat`. По выше озвученной причине берем `50` поле с конца.

```
cat ${PID}/stat | rev | awk '{printf $50}' | rev
```

### Вывод TIME (общее время процессора, затраченное на выполнение процессора)

Параметр `TIME` является суммой параметров `14, 15, 16 и 17` полей файла `/proc/<PID>/stat`. Аналогично осуществляем выбор полей  `36, 37, 38 и 39` с конца.

```
cat ${PID}/stat | rev | awk '{print $36" "$37" "$38" "$39}' | rev | awk '{sum=$1+$2+$3+$4}END{print sum/100}' | awk '{("date +%M:%S -d @"$1)| getline $1}1'
```
### Вывод COMMAND (команда запуска процессора)

Параметр `COMMAND` берем из файла `/proc/<PID>/cmdline`.

```
cat ${PID}/cmdline
```

Либо, если `/proc/<PID>/cmdline` пуст, то берем имя
команды, связанное с процессом из `/proc/<PID>/comm`.

```
cat ${PID}/comm
```

### Пример вывода скрипта

```
[root@localhost ~]# bash proc.sh
/proc/1 ? S 01:00 /usr/lib/systemd/systemd--switched-root--system--deserialize22
2 ? S 00:00 [kthreadd]
4 ? S 00:00 [kworker/0:0H]
6 ? S 00:05 [ksoftirqd/0]
7 ? S 00:00 [migration/0]
8 ? S 00:00 [rcu_bh]
9 ? R 00:36 [rcu_sched]
10 ? S 00:00 [lru-add-drain]
11 ? S 00:00 [watchdog/0]
13 ? S 00:00 [kdevtmpfs]
14 ? S 00:00 [netns]
15 ? S 00:00 [khungtaskd]
16 ? S 00:00 [writeback]
17 ? S 00:00 [kintegrityd]
18 ? S 00:00 [bioset]
19 ? S 00:00 [bioset]
20 ? S 00:00 [bioset]
21 ? S 00:00 [kblockd]
22 ? S 00:00 [md]
23 ? S 00:00 [edac-poller]
24 ? S 00:00 [watchdogd]
30 ? S 00:00 [kswapd0]
31 ? S 00:00 [ksmd]
32 ? S 00:00 [khugepaged]
33 ? S 00:00 [crypto]
41 ? S 00:00 [kthrotld]
42 ? S 00:01 [kworker/u256:1]
43 ? S 00:00 [kmpath_rdacd]
44 ? S 00:00 [kaluad]
45 ? S 00:00 [kpsmoused]
47 ? S 00:00 [ipv6_addrconf]
60 ? S 00:00 [deferwq]
97 ? S 00:00 [kauditd]
276 ? S 00:00 [mpt_poll_0]
277 ? S 00:00 [nfit]
278 ? S 00:00 [mpt/0]
279 ? S 00:00 [ata_sff]
282 ? S 00:00 [scsi_eh_0]
283 ? S 00:00 [scsi_tmf_0]
288 ? S 00:02 [kworker/u256:2]
289 ? S 00:00 [scsi_eh_1]
290 ? S 00:00 [scsi_tmf_1]
292 ? S 00:00 [scsi_eh_2]
293 ? S 00:00 [scsi_tmf_2]
306 ? S 00:20 [irq/16-vmwgfx]
307 ? S 00:00 [ttm_swap]
371 ? S 00:00 [kdmflush]
372 ? S 00:00 [bioset]
382 ? S 00:00 [kdmflush]
383 ? S 00:00 [bioset]
395 ? S 00:00 [bioset]
396 ? S 00:00 [xfsalloc]
397 ? S 00:00 [xfs_mru_cache]
398 ? S 00:00 [xfs-buf/dm-0]
399 ? S 00:00 [xfs-data/dm-0]
400 ? S 00:00 [xfs-conv/dm-0]
401 ? S 00:00 [xfs-cil/dm-0]
402 ? S 00:00 [xfs-reclaim/dm-]
403 ? S 00:00 [xfs-log/dm-0]
404 ? S 00:00 [xfs-eofblocks/d]
405 ? S 00:38 [xfsaild/dm-0]
406 ? S 00:00 [kworker/0:1H]
488 ? S 00:00 /usr/lib/systemd/systemd-journald
518 ? S 00:00 /usr/sbin/lvmetad-f
528 ? S 00:02 /usr/lib/systemd/systemd-udevd
575 ? S 00:00 [xfs-buf/sda1]
578 ? S 00:00 [xfs-data/sda1]
580 ? S 00:00 [xfs-conv/sda1]
581 ? S 00:00 [xfs-cil/sda1]
583 ? S 00:00 [kworker/u257:0]
584 ? S 00:00 [xfs-reclaim/sda]
585 ? S 00:00 [hci0]
586 ? S 00:00 [xfs-log/sda1]
587 ? S 00:00 [hci0]
589 ? S 00:00 [kworker/u257:2]
590 ? S 00:00 [xfs-eofblocks/s]
592 ? S 00:00 [xfsaild/sda1]
650 ? S 00:00 /sbin/auditd
673 ? S 00:00 /usr/bin/dbus-daemon--system--address=systemd:--nofork--nopidfile--systemd-activation
675 ? S 00:04 /usr/sbin/NetworkManager--no-daemon
676 ? S 00:00 /usr/lib/polkit-1/polkitd--no-debug
678 ? S 00:00 /usr/bin/VGAuthService-s
679 ? S 01:55 /usr/bin/vmtoolsd
680 ? S 00:00 /usr/lib/systemd/systemd-logind
685 ? S 00:00 /usr/sbin/chronyd
700 ? S 00:02 /usr/sbin/crond-n
710 tty1 S 00:00 /sbin/agetty--nocleartty1linux
995 ? S 00:13 /usr/bin/python2-Es/usr/sbin/tuned-l-P
997 ? S 00:36 /usr/sbin/sshd-D
1002 ? S 00:06 /usr/sbin/rsyslogd-n
1162 ? S 00:00 /usr/libexec/postfix/master-w
1166 ? S 00:00 [qmgr]
1325 ? S 00:00 sh/root/.vscode-server/bin/441438abd1ac652551dbe4d408dfcec8a499b8bf/bin/code-server--start-server--host=127.0.0.1--accept-server-license-terms--enable-remote-auto-shutdown--port=0--telemetry-levelall--connection-token-file/root/.vscode-server/.441438abd1ac652551dbe4d408dfcec8a499b8bf.token
1337 ? S 02:55 /root/.vscode-server/bin/441438abd1ac652551dbe4d408dfcec8a499b8bf/node/root/.vscode-server/bin/441438abd1ac652551dbe4d408dfcec8a499b8bf/out/server-main.js--start-server--host=127.0.0.1--accept-server-license-terms--enable-remote-auto-shutdown--port=0--telemetry-levelall--connection-token-file/root/.vscode-server/.441438abd1ac652551dbe4d408dfcec8a499b8bf.token
1411 ? S 02:37 /root/.vscode-server/bin/441438abd1ac652551dbe4d408dfcec8a499b8bf/node/root/.vscode-server/bin/441438abd1ac652551dbe4d408dfcec8a499b8bf/out/bootstrap-fork--type=ptyHost--logsPath/root/.vscode-server/data/logs/20230219T031028
1474 ? S 00:12 /bin/bash--init-file/root/.vscode-server/bin/441438abd1ac652551dbe4d408dfcec8a499b8bf/out/vs/workbench/contrib/terminal/browser/media/shellIntegration-bash.sh
44716 ? S 00:02 [sshd]
44720 ? S 00:00 [bash]
44774 ? S 00:10 /root/.vscode-server/bin/441438abd1ac652551dbe4d408dfcec8a499b8bf/node/root/.vscode-server/bin/441438abd1ac652551dbe4d408dfcec8a499b8bf/out/bootstrap-fork--type=extensionHost--transformURIs--useHostProxy=false
44817 ? S 00:00 sshd: root@pts/18
44821 tty70 S 00:07 [bash]
49314 ? S 00:00 [pickup]
49316 ? S 00:02 [kworker/0:1]
49375 ? S 00:00 [cifsiod]
49376 ? S 00:00 [cifsoplockd]
49424 ? S 00:00 [cifsd]
49464 ? S 00:00 [kworker/0:3]
49468 ? S 00:00 [sleep]
49527 ? S 00:00 [sshd]
49528 ? S 00:00 [sshd]
49529 ? S 00:00 [kworker/0:0]
49530 ? S 00:00 sshd: root@pts/6
49534 tty2 S 00:00 [bash]
49553 tty2 S 00:03 [bash]
49554 н/у н/у н/у н/у
49555 н/у н/у н/у н/у
49556 н/у н/у н/у н/у
49557 н/у н/у н/у н/у
49558 н/у н/у н/у н/у
```