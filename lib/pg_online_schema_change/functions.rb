FIX_SERIAL_SEQUENCE = <<~SQL.freeze
  CREATE OR REPLACE FUNCTION fix_serial_sequence(_table regclass, _newtable text)
  RETURNS void AS
  $func$
  DECLARE
  _sql text;
  BEGIN

  -- Update serial columns to ensure copied table doesn't follow same sequence as primary table
  SELECT INTO _sql
      string_agg('CREATE SEQUENCE ' || seq, E';\n') || E';\n'
      || string_agg(format('ALTER SEQUENCE %s OWNED BY %I.%I'
                          , seq, _newtable, a.attname), E';\n') || E';\n'
      || 'ALTER TABLE ' || quote_ident(_newtable) || E'\n  '
      || string_agg(format($$ALTER %I SET DEFAULT nextval('%s'::regclass)$$
                                  , a.attname, seq), E'\n, ')
  FROM   pg_attribute  a
  JOIN   pg_attrdef    ad ON ad.adrelid = a.attrelid
                      AND ad.adnum   = a.attnum
      , quote_ident(_newtable || '_' || a.attname || '_seq') AS seq
  WHERE  a.attrelid = _table
  AND    a.attnum > 0
  AND    NOT a.attisdropped
  AND    a.atttypid = ANY ('{int,int8,int2}'::regtype[])
  AND    ad.adsrc = 'nextval('''
          || (pg_get_serial_sequence (a.attrelid::regclass::text, a.attname))::regclass
          || '''::regclass)'
  ;

  IF _sql IS NOT NULL THEN
  EXECUTE _sql;
  END IF;

  END
  $func$  LANGUAGE plpgsql VOLATILE;
SQL
