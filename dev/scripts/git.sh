#!/bin/bash

# Função para exibir uma mensagem de erro
error() {
    echo -e "\033[31m[Erro]\033[0m $1"
}

# Função para exibir uma mensagem de sucesso
success() {
    echo -e "\033[32m[Sucesso]\033[0m $1"
}

# Função para capturar a entrada do usuário com validação
prompt() {
    local prompt_text=$1
    local var_name=$2
    local validation_func=$3

    while true; do
        read -p "$prompt_text: " value
        if [ -z "$value" ]; then
            error "O campo não pode estar vazio."
        elif [ -n "$validation_func" ]; then
            if ! $validation_func "$value"; then
                error "Entrada inválida."
            else
                break
            fi
        else
            break
        fi
    done

    eval $var_name=\$value
}

# Função para validar o email
validate_email() {
    local email_regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    if [[ $1 =~ $email_regex ]]; then
        return 0
    else
        return 1
    fi
}

# Função para rollback
rollback() {
    git config --global --unset user.name
    git config --global --unset user.email
    rm -f ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
    success "Rollback realizado."
    exit 1
}

# Função para gerar as chaves SSH
generate_ssh_key() {
    if ssh-keygen -t rsa -b 4096 -C "$email" -f ~/.ssh/id_rsa -N ""; then
        success "Chaves SSH geradas com sucesso."
    else
        error "Falha ao gerar as chaves SSH."
        rollback
    fi
}

# Início do script
echo "Configuração das credenciais do Git e geração de chave SSH"

# Captura o nome do usuário
prompt "Digite seu nome para o Git" username

# Captura o email do usuário
prompt "Digite seu email para o Git" email validate_email

# Define as credenciais do Git
git config --global user.name "$username"
git config --global user.email "$email"
success "Credenciais do Git configuradas com sucesso."

# Gera as chaves SSH
generate_ssh_key

# Exibe a chave pública para o usuário adicionar no GitHub
echo "Sua chave pública SSH foi gerada:"
cat ~/.ssh/id_rsa.pub

# Pergunta se o usuário deseja continuar
read -p "Deseja continuar com essa configuração? (s/n): " confirm

if [[ "$confirm" =~ ^[Nn]$ ]]; then
    rollback
fi

success "Configuração finalizada com sucesso. Não se esqueça de adicionar a chave pública no GitHub."

exit 0
