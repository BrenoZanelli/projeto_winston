import sqlite3

class DatabaseManager:
    def __init__(self, db_path='winston.db'):
        self.db_path = db_path
        self._init_db()
    
    def _get_conection(self):
        return sqlite3.connect(self.db_path)
    
    def _init_db(self):
        with self._get_conection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                           CREATE TABLE IF NOT EXISTS historico (
                           id INTEGER PRIMARY KEY AUTOINCREMENT,
                           role TEXT NOT NULL,
                           content TEXT NOT NULL,
                           timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
                           )
                        ''')
            conn.commit()

    def salvar_mensagem(self, role, content):
        with self._get_conection() as conn:
            cursor = conn.cursor()
            cursor.execute('INSERT INTO historico (role, content) VALUES (?,?)', (role, content))
            conn.commit()

    def carregar_historico(self):
        with self._get_conection() as conn:
            cursor = conn.cursor()
            try:
                cursor.execute('SELECT role, content FROM historico ORDER BY timestamp ASC')
                mensagens = cursor.fetchall() # Corrigido para plural

                # Adicionada a vírgula que faltava após m[0]
                return [{"role": m[0], "parts": [{"text": m[1]}]} for m in mensagens]
            except sqlite3.OperationalError:
                return []
            
    def limpar_historico(self):
        with self._get_conection() as conn:
            cursor = conn.cursor()
            cursor.execute('DELETE FROM historico')
            conn.commit()