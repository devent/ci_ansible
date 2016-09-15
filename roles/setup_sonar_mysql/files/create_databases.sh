#!/bin/bash
NAME="$1"; shift
ROOT_PASSWORD="$1"; shift
SONAR_USER="$1"; shift
SONAR_PASSWORD="$1"; shift

mysql=( mysql --protocol=socket -uroot -p"$ROOT_PASSWORD" )
docker exec $NAME bash -c "${mysql[*]} <<EOF
CREATE DATABASE IF NOT EXISTS tmpUserVar;
USE tmpUserVar;
DELIMITER \$\$
CREATE DEFINER=root@localhost PROCEDURE UserVer(
    IN eUser VARCHAR(50),
    IN ePass VARCHAR(50))
sp_np:BEGIN
    /*  | Variable Declaration | */
        DECLARE vUser VARCHAR(50) DEFAULT '';
        DECLARE vPass VARCHAR(50) DEFAULT '';
        DECLARE vReg INT(8) DEFAULT 0;
    /*  | Variable Asignation | */
        SET vUser       =eUser;
        SET vPass       =ePass;
    /*  | WorkPlace |   */
    SET vReg=(SELECT COUNT(*) FROM mysql.user WHERE User=vUser);
    IF (vReg=0) THEN # If Exists EXECUTE
        SET @CREATE_USER=CONCAT(\"CREATE USER \",\"'\",vUser,\"'\",\" IDENTIFIED BY '\",vPass,\"';\");
        PREPARE CREATE_USER FROM @CREATE_USER; EXECUTE CREATE_USER; DEALLOCATE PREPARE CREATE_USER;
        LEAVE sp_np;
    ELSE
        SELECT '01' AS sERROR,'User exists.' AS sDESC_ERROR;
        LEAVE sp_np;
    END IF;
    END \$\$
DELIMITER ;

CREATE DATABASE IF NOT EXISTS $SONAR_USER CHARACTER SET utf8 COLLATE utf8_general_ci;
CALL UserVer('$SONAR_USER', '$SONAR_PASSWORD');
GRANT ALL ON $SONAR_USER.* TO '$SONAR_USER'@'%' IDENTIFIED BY '$SONAR_PASSWORD';
GRANT ALL ON $SONAR_USER.* TO '$SONAR_USER'@'localhost' IDENTIFIED BY '$SONAR_PASSWORD';
FLUSH PRIVILEGES;
DROP PROCEDURE UserVer;
DROP DATABASE tmpUserVar;
EOF"
