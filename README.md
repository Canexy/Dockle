# 🐳 Dockle - Oracle 10g en Docker

Este proyecto documenta y automatiza el proceso de migración de una base de datos Oracle 10g desde una máquina virtual (.vdi) a un contenedor Docker. Está pensado para entornos educativos, pruebas o para quienes necesiten mantener sistemas heredados de Oracle 10g en un entorno más portable.

## 📌 Autores

- Mario Valiño Canalejas
- Álvaro Vázquez Vázquez

## 📦 Requisitos

- Docker instalado y funcionando
- Archivo de volcado `.dmp` exportado desde Oracle 10g
- Imagen base compatible (Ubuntu 14.04)

## 🔧 Proceso de Migración

1. **Exportación de la base de datos desde Oracle 10g**

   ```bash
   exp 'sys/oracle as sysdba' full=y file=backup_full.dmp log=backup_full.log
   ```

2. **Transferencia del volcado al host Docker**

   ```bash
   scp backup_full.dmp user@host:/ruta/de/destino/
   ```

3. **Descarga de la imagen base**

   ```bash
   docker pull ubuntu:14.04
   ```

4. **Creación de imagen personalizada con Oracle 10g**

   Basado en un `Dockerfile` que instala Oracle 10g XE, sus dependencias, y configura puertos, usuarios y variables de entorno necesarias.

5. **Construcción y ejecución del contenedor**

   ```bash
   docker build -t oracle-xe .
   docker run -d -p 1521:1521 -p 8080:8080 --name oracle-xe oracle-xe
   ```

6. **Copia del volcado al contenedor**

   ```bash
   docker cp backup_full.dmp oracle-xe:/tmp/backup.dmp
   ```

7. **Ajuste de permisos en el contenedor**

   ```bash
   docker exec -it oracle-xe /bin/bash
   chown oracle:dba /tmp
   chmod 777 /tmp
   su - oracle
   ```

8. **Importación del volcado dentro del contenedor**

   ```bash
   imp SYSTEM/oracle file=/tmp/backup.dmp log=/tmp/import.log full=y
   ```

9. **Verificación desde el sistema anfitrión**

   ```bash
   sqlplus SYS/oracle@localhost/XE as sysdba
   ```

   Comprobación de tablas:

   ```sql
   SELECT table_name FROM all_tables WHERE upper(owner) = 'E4707';
   ```

## 📁 Estructura del Repositorio

- `Dockerfile`: Archivo principal que define la imagen con Oracle 10g XE.
- `startup.sh`: Script que lanza SSH, Oracle Listener y la base de datos.
- Otros archivos de configuración necesarios para la correcta ejecución de Oracle XE.

## 🛠 Notas técnicas

- Se utiliza Oracle 10g XE para arquitectura de 32 bits.
- La imagen se basa en Ubuntu 14.04 por compatibilidad con el entorno original.
- Se exponen los puertos 1521 (SQL*Net), 8080 (APEX) y 22 (SSH).

## 📜 Licencia

Este proyecto es de uso educativo y no oficial. Oracle Database XE es propiedad de Oracle Corporation y se deben aceptar sus términos para su uso.
