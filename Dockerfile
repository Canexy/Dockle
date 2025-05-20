FROM ubuntu:14.04

LABEL maintainer="Tu Nombre <tu@email.com>"

ENV ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server \
    LD_LIBRARY_PATH=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server/lib \
    PATH=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server/bin:$PATH \
    ORACLE_SID=XE \
    NLS_LANG=AMERICAN_AMERICA.WE8MSWIN1252

RUN apt-get update && \
    apt-get install -yq software-properties-common && \
    dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -yq \
        bc:i386 \
        libaio1:i386 \
        libc6:i386 \
        net-tools \
        openssh-server \
        wget \
        sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /var/run/sshd && \
    echo 'root:admin' | chpasswd && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd && \
    echo "export VISIBLE=now" >> /etc/profile && \
    wget --no-check-certificate -O /tmp/oracle-xe.deb \
      https://oss.oracle.com/debian/dists/unstable/non-free/binary-i386/oracle-xe_10.2.0.1-1.1_i386.deb && \
    dpkg -i /tmp/oracle-xe.deb && \
    rm /tmp/oracle-xe.deb && \
    sed -i 's/51200K/4096K/' $ORACLE_HOME/config/scripts/cloneDBCreation.sql && \
    printf "%s\n" 8080 1521 oracle oracle y | /etc/init.d/oracle-xe configure && \
    mkdir -p $ORACLE_HOME/network/log && \
    chown -R oracle:dba $ORACLE_HOME && \
    chmod -R 775 $ORACLE_HOME/network && \
    sed -i 's/(HOST = [^)]+)/(HOST = 0.0.0.0)/g' $ORACLE_HOME/network/admin/listener.ora && \
    sed -i 's/(HOST = [^)]+)/(HOST = 0.0.0.0)/g' $ORACLE_HOME/network/admin/tnsnames.ora && \
    echo "export ORACLE_HOME=$ORACLE_HOME" >> /etc/bash.bashrc && \
    echo "export PATH=$ORACLE_HOME/bin:\$PATH" >> /etc/bash.bashrc && \
    echo "export LD_LIBRARY_PATH=$ORACLE_HOME/lib" >> /etc/bash.bashrc && \
    # Ensure ORACLE_SID is exported for oracle user
    echo "export ORACLE_SID=XE" >> /etc/bash.bashrc && \
    echo '#!/bin/bash' > /startup.sh && \
    echo 'service ssh start' >> /startup.sh && \
    echo 'sleep 3' >> /startup.sh && \
    # Start listener with ORACLE_SID set for oracle user
    echo 'su -p oracle -c "export ORACLE_SID=XE && $ORACLE_HOME/bin/lsnrctl start"' >> /startup.sh && \
    echo 'sleep 5' >> /startup.sh && \
    echo 'su -p oracle -c "export ORACLE_SID=XE && echo startup | $ORACLE_HOME/bin/sqlplus -s / as sysdba"' >> /startup.sh && \
    echo 'tail -f $ORACLE_HOME/network/log/listener.log' >> /startup.sh && \
    chmod +x /startup.sh && \
    rm -f $ORACLE_HOME/network/admin/listener.ora && \
    cat <<EOF > $ORACLE_HOME/network/admin/listener.ora
# listener.ora Network Configuration File:

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (SID_NAME = PLSExtProc)
      (ORACLE_HOME = /usr/lib/oracle/xe/app/oracle/product/10.2.0/server)
      (PROGRAM = extproc)
    )
  )

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC_FOR_XE))
      (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
    )
  )
EOF

EXPOSE 22 1521 8080

CMD ["/startup.sh"]

