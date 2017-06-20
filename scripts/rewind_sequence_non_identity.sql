declare
   l_select_col VARCHAR2(4000);
   l_assign_col VARCHAR2(4000);

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
                    , trigs.trigger_name
                    , seqs.sequence_name
                    , trigs.trigger_body
                 from user_tables tabs
                 join user_triggers trigs
                   on trigs.table_name = tabs.table_name
                 join user_dependencies deps
                   on deps.name = trigs.trigger_name
                 join user_sequences seqs
                   on seqs.sequence_name = deps.referenced_name
                where tabs.table_name in (<table_list>))
   LOOP
      l_select_col := REPLACE(
                         REGEXP_SUBSTR(
                            REGEXP_SUBSTR(
                               REPLACE(UPPER(SUBSTR(rec.trigger_body, 1, 4000)), CHR(10)), 
                               'SELECT '||rec.sequence_name||'[A-Z0-9.: ]+FROM'), 
                            ':NEW.[A-Z0-9_]+'),
                         ':NEW.');
   
      l_assign_col := REPLACE(
                         REGEXP_SUBSTR(
                            REGEXP_SUBSTR(
                               REPLACE(UPPER(SUBSTR(rec.trigger_body, 1, 4000)), CHR(10)), 
                               ':NEW\.[A-Z0-9_ ]+:=[ ]+'||rec.sequence_name), 
                            ':NEW.[A-Z0-9_]+'),
                         ':NEW.');
                         
      IF NVL(l_select_col, l_assign_col) IS NULL
      THEN
         RAISE_APPLICATION_ERROR (-20999, 'Assignment column for sequence '|| rec.sequence_name ||' not found!');
      END IF;
                         
      rewind_seq(rec.table_name, NVL(l_select_col, l_assign_col), rec.sequence_name);
   END LOOP;
   
   COMMIT;
end;

