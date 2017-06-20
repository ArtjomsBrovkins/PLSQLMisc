declare
   l_seq_name VARCHAR2(4000);

   procedure rewind_seq(
      p_table_name    VARCHAR2
     ,p_column_name   VARCHAR2
     ,p_sequence_name VARCHAR2
   )
   IS
      l_max PLS_INTEGER;
      l_cur PLS_INTEGER;
      l_tmp PLS_INTEGER;
   begin
      execute immediate 'SELECT '|| p_sequence_name ||'.nextval FROM dual' INTO l_cur;
      dbms_output.put_line('Sequence ' || p_sequence_name || ' current value is '|| l_cur);
      execute immediate 'SELECT max('|| p_column_name ||') FROM '||p_table_name INTO l_max;
      dbms_output.put_line('Table''s ' || p_table_name || ' current max value is '|| l_max); 
         
      IF (l_max-l_cur+1) != 0
      THEN
         execute immediate 'alter sequence '|| p_sequence_name ||' INCREMENT BY '||TO_CHAR(l_max-l_cur+1);
         execute immediate 'SELECT '|| p_sequence_name ||'.nextval FROM dual' INTO l_tmp;
      END IF;
      
      execute immediate 'alter sequence '|| p_sequence_name ||' INCREMENT BY 1';
      execute immediate 'SELECT '|| p_sequence_name ||'.nextval FROM dual' INTO l_cur;
      dbms_output.put_line('Sequence ' || p_sequence_name || ' current value is '|| l_cur);
   end rewind_seq;
begin
   
   FOR rec in (select tabs.table_name
                    , cols.column_name
                    , cols.data_default
                 from user_tables tabs
                 join user_tab_columns cols
                   on tabs.table_name = cols.table_name
                  and cols.data_default is not null
                where tabs.table_name in (<table_list>))
   LOOP
      -- Additional PL/SQL due to WIDEMEMO column usage in dba_tab_columns
      l_seq_name := REGEXP_SUBSTR(SUBSTR(rec.data_default, 1, 4000), '[A-Z0-9]+\$\$_[A-Z0-9]+');
      
      IF l_seq_name IS NULL
      THEN
         RAISE_APPLICATION_ERROR (-20999, 'Sequence for column '|| rec.table_name ||'.'|| rec.column_name ||' not found!');
      END IF;
      
      rewind_seq(rec.table_name, rec.column_name, l_seq_name);
   END LOOP;
   
   COMMIT;
end;

