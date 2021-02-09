# Requisitos

* Ruby 2.5.3

# Instalação:

1. Instalar as Gems

```sh
$ gem install bundler -v '2.1.4'
$ bin/bundle install
```

2. Copiar o `.env.test` para `.env` e configurar os campos com os valores apropriados.

3. Copiar o `config/database.yml.sample` para `config/database.yml` e configurar para os bancos de desenvolvimento e teste. Nota: deve-se dar ao usuário permissão para criar bancos no PostgreSQL.

4. Criar o banco com as tabelas para os testes

```sh
$ bin/rake db:create
$ bin/rake db:migrate db:test:prepare
```

## Rodando o projeto:

```sh
# Iniciar o rails server
$ bin/rails s
```

## Rodando os testes automatizados:

```sh
$ bin/rspec spec/
```
