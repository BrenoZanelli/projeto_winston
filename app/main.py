import streamlit as st
import os
from database import DatabaseManager
from openai import OpenAI

# 1. ISSO DEVE FICAR NO TOPO ABSOLUTO (Configuração da Interface)
st.set_page_config(page_title="Winston IA", page_icon="🤖")
st.title("🤖 Winston IA (Versão POO)")

# --- INICIALIZAÇÃO DO BANCO DE DADOS ---
if "db" not in st.session_state:
    st.session_state.db = DatabaseManager()

db = st.session_state.db

#----CONFIGURAÇÃO DA IA LOCAL (CONEXÃO COM O LLAMA.CPP)----

if "ai_client" not in st.session_state:
    st.session_state.ai_client = OpenAI(
        # Graças ao network_mode: host, o container vai falar direto com o seu Linux físico
        base_url="http://127.0.0.1:8080/v1"
    )
client = st.session_state.ai_client


# --- BARRA LATERAL ---
with st.sidebar:
    st.header("Configurações")
    if st.button("Limpar Histórico"):
        db.limpar_historico()
        st.rerun()

#---EXIBIÇÃO DAS MENSAGENS (lendo direto do banco de dados)----
#---como o llama não consegue gerenciar sessões internas, lemos o histórico real guardado no winston.db

historico_banco=db.carregar_historico()

for msg in historico_banco:
    #converte o formato do banco para exibição no Streamlit
    role="user" if msg["role"]=="user" else "assistent"
    # m["parts"][0]["text"] extrai o texto do formato que a classe salvou
    texto_mensagem=msg["parts"][0]["text"]

    with st.chat_message(role):
        st.markdown(texto_mensagem)

#----ENTRADA DO USUÁRIO----

if prompt:= st.chat_input("Digite algo para o Winston..."):
    #exibe a mensagem que o usuario digitou na tela
    with st.chat_message("user"):
        st.markdown(prompt)

    #salva a pergunta no banco de dados
    db.salvar_mensagem("user", prompt)

    #resposta do winston
    with st.chat_message("assistant"):
        with st.spinner("Winston está processando..."):
            try:
                # 1. Criamos a lista de mensagens no padrão que o Llama-server espera
                # Começamos definindo o comportamento do Winston (System Instruction)
                mensagens_openai= [
                    {
                        "role": "system",
                        "content": "Você é Winston, o assistente de IA de Breno. Criado para ser um mentor e ajuda-lo nos estudos da área de tecnologia no geral."

                    }
                ]

                # 2. Alimentamos o Llama com o histórico antigo para ele ter memória
                for msg in historico_banco:
                    role_ajustado="user" if msg["role"]== "user" else "assistant"
                    mensagens_openai.append({
                        "role": role_ajustado,
                        "content": msg["parts"][0]["text"]
                    })
                
                # 3. Por fim, adicionamos a pergunta atual do prompt
                mensagens_openai.append({"role": "user","content": prompt})

                # 4. Fazemos a chamada real para a sua RTX 3050!
                response=client.chat.completions.create(
                    model="local-model",
                    messages=mensagens_openai
                )

                #Extraímos o texto da resposta
                resposta_texto= response.choices[0].message.content
                st.markdown(resposta_texto)

                #salva a resposta do Winston no banco de dados
                db.salvar_mensagem("model", resposta_texto)

                #recarrega a página para atualizar o fluxo de exibição perfeitamente
                st.rerun()

                
            except Exception as e:
                st.error(f"Erro na comunicação local: {e}")