from dill import loads
from psycopg2.extensions import cursor as _cursor
from psycopg2.extensions import connection as _connection

class DillConnection(_connection):
    def cursor(self, *args, **kwargs):
        kwargs.setdefault('cursor_factory', DillCursor)
        return super().cursor(*args, **kwargs)

class DillCursor(_cursor):
    def fetchone(self):
        t = super().fetchone()
        if t is not None:
            return loads(t[0])._bind(cur=self)

    def fetchmany(self, size=None):
        return (loads(t)._bind(cur=self) for t, in super().fetchmany(size))

    def fetchall(self):
        return (loads(t)._bind(cur=self) for t, in super().fetchall())

    def __iter__(self):
        try:
            it = super().__iter__()
            while True:
                t, = next(it)
                yield loads(t)._bind(cur=self)
        except StopIteration:
            return
