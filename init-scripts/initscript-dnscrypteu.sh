#! /bin/sh
### BEGIN INIT INFO
# Provides:          dnscrypt-proxy
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: dnscrypt-proxy
# Description:       dnscrypt-proxy secure DNS client
### END INIT INFO

# Author: Simon Clausen <kontakt@simonclausen.dk> 
# Additional edits by: Jan Brennen https://github.com/janbrennen

PATH=/usr/sbin:/usr/bin:/sbin:/bin
DAEMON=/usr/local/sbin/dnscrypt-proxy
NAME=dnscrypt-proxy
ADDRESS1=77.66.84.233
ADDRESS2=176.56.237.171
PNAME1=2.dnscrypt-cert.resolver2.dnscrypt.eu
PNAME2=2.dnscrypt-cert.resolver1.dnscrypt.eu
PKEY1=3748:5585:E3B9:D088:FD25:AD36:B037:01F5:520C:D648:9E9A:DD52:1457:4955:9F0A:9955
PKEY2=67C0:0F2C:21C5:5481:45DD:7CB4:6A27:1AF2:EB96:9931:40A3:09B6:2B8D:1653:1185:9C66


## Start-stop-daemon stuff 
PIDFILE1=/var/run/$NAME-1.pid
PIDFILE2=/var/run/$NAME-2.pid
USER=dnscrypt
DESC="Secure DNS Proxy"
DAEMON_OPTS="--daemonize --user=dnscrypt --local-address=127.0.0.1 --resolver-address=$ADDRESS1 --provider-name=$PNAME1 --provider-key=$PKEY1"
DAEMON_OPTS2="--daemonize --user=dnscrypt --local-address=127.0.0.2 --resolver-address=$ADDRESS2 --provider-name=$PNAME2 --provider-key=$PKEY2"

test -x $DAEMON || exit 0
. /lib/lsb/init-functions

case "$1" in
  start)
    log_daemon_msg "Starting $DESC" $NAME
    start-stop-daemon --start --quiet --pidfile $PIDFILE1 --background --exec\
      $DAEMON -- $DAEMON_OPTS --pidfile=$PIDFILE1
    RET1=$?
    start-stop-daemon --start --quiet --pidfile $PIDFILE2 --background --exec\
      $DAEMON -- $DAEMON_OPTS2 --pidfile=$PIDFILE2
    RET2=$?
    RET=$((RET1+RET2))
    log_end_msg $RET
    ;;
  stop)
    log_daemon_msg "Stopping $DESC" $NAME
    start-stop-daemon --stop --quiet --pidfile $PIDFILE1 \
        --exec $DAEMON
    RET1=$?
    start-stop-daemon --stop --quiet --pidfile $PIDFILE2 \
        --exec $DAEMON
    RET2=$?
    RET=$((RET1+RET2))
    rm -f $PIDFILE1 $PIDFILE2
    log_end_msg $RET
    ;;
  restart|force-reload)
    sh $0 stop
    sleep 1
    sh $0 start
    ;;
  status)
    status_of_proc "$DAEMON" "$NAME" && exit 0 || exit $?
    ;;
  *)
    echo "Usage: /etc/init.d/$NAME {start|stop|restart}" >&2
    exit 1
    ;;
esac

exit 0
