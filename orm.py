from collections import namedtuple

class Object:
    __cache__ = {}
    def __new__(cls, oid, data, cur=None):
        if oid not in cls.__cache__:
            rv = cls.__cache__[oid] = super().__new__(cls)
            rv.__init__(oid, data, cur)
        return cls.__cache__[oid]

    def __getnewargs__(self):
        asof = self.data['asof']
        from_tstz, to_tstz = asof.split(',')
        interval = from_tstz[0] + to_tstz[-1]
        from_tstz, to_tstz = from_tstz[1:], to_tstz[:-1]
        self.data['asof'] = from_tstz, to_tstz, interval
        return self.oid, self.data, self.cur

    def __init__(self, oid, data, cur=None):
        self.oid, self.data, self.cur = oid, data, cur

    def _bind(self, cur):
        self.cur = cur
        return self

    def __repr__(self):
        return f'{type(self).__name__}({self.data}, {self.cur})'

class Base(Object):
    id = property(lambda self: self.data['id'])

    @classmethod
    def select_by_id(cls, cur, id):
        query = f'select {cls._object} from orm."{cls._table}" where id = %s'
        cur.execute(query, (id,))
        return cur.fetchone()

    def update_field(self, field, value):
        query = f'update {self._table} set {field} = %s where id = %s'
        self.cur.execute(query, (value, self.id))
        self.data[field] = value

    @property
    def asof(self):
        return self.data['asof']

class Ship(Base):
    _table, _object = 'objects.ships', 'ship'

    @property
    def shipyard(self):
        return System.select_by_id(self.cur, self.data['shipyard'])
    @shipyard.setter
    def shipyard(self, value):
        self.update_field('shipyard', value)

    @property
    def location(self):
        return System.select_by_id(self.cur, self.data['location'])
    @location.setter
    def location(self, value):
        self.update_field('location', value.id)

    @property
    def flag(self):
        return Civilization.select_by_id(self.cur, self.data['flag'])
    @flag.setter
    def flag(self, value):
        self.update_field('flag', value.id)

class System(Base):
    _table, _object = 'objects.systems', 'system'

    def __getnewargs__(self):
        self.data['tuning'] = eval(self.data['tuning'])
        return super().__getnewargs__()

    @property
    def controller(self):
        return Civilization.select_by_id(self.cur, self.data['controller'])
    @controller.setter
    def controller(self, value):
        return self.update_field('controller', value.id)

    @property
    def tuning(self):
        return self.data['tuning']
    @tuning.setter
    def tuning(self, value):
        return self.update_field('tuning', value)

    @property
    def production(self):
        return self.data['production']
    @production.setter
    def production(self, value):
        return self.update_field('production', value)

    @property
    def mode(self):
        return self.data['mode']
    @mode.setter
    def mode(self, value):
        return self.update_field('mode', value)

class Civilization(Base):
    _table, _object = 'objects.civilizations', 'civilization'

    @property
    def name(self):
        return self.data['name']
    @name.setter
    def name(self, value):
        return self.update_field('name', value)

    @property
    def homeworld(self):
        return System.select_by_id(self.cur, self.data['homeworld'])
    @homeworld.setter
    def homeworld(self, value):
        return self.update_field('homeworld', value)

    @property
    def token(self):
        return self.data['token']
    @token.setter
    def token(self, value):
        return self.update_field('token', value)

    @property
    def ships(self):
        query = 'select ship from orm."objects.ships" where flag = %s'
        self.cur.execute(query, (self.id,))
        return iter(self.cur)
