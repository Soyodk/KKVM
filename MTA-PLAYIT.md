# Servidor MTA no Codespace

## Iniciar

Execute na raiz do workspace:

```bash
./start.sh
```

O script inicia o MTA e conecta o túnel `MTA` já configurado no Portwarp. Para parar o servidor e esse túnel, use `./stop.sh`.

## Portwarp

O túnel `MTA` deve estar habilitado como **BOTH (TCP + UDP)** e apontar para `127.0.0.1:22003`. UDP chega ao MTA; TCP chega a um servidor HTTP somente do cache `http-client-files` do MTA. O HTTP interno do MTA fica na porta local `22005`, sem ser encaminhado. A configuração define `httpdownloadurl` para o hostname público Portwarp, evitando que os clientes tentem baixar arquivos pelo IP externo do Codespace. O Portwarp está configurado para a porta pública `18661`; confira o endereço/hostname no painel ou com:

```bash
pwrp tunnels
```

No cliente MTA, conecte a `ljgdjosy.free.tryportwarp.cc:18661`. Se alterar o hostname ou a porta no Portwarp, atualize também `httpdownloadurl` em `config/mtaserver.conf`. O Codespace precisa permanecer ativo.

Não é necessário criar encaminhamento de portas no painel do Codespaces. A porta ASE `22126/UDP` é opcional e não é necessária para conexão direta.

## Servidor

O setup baixa o servidor Linux x86_64 e os recursos padrão oficiais do MTA, e instala o conteúdo de `[ND]GOIABARP.rar`. Os arquivos do servidor ficam em `.runtime/`, que não é versionado.

Edite `config/mtaserver.conf` para alterar nome, slots e portas. O servidor está inicialmente sem senha. Recursos/scripts próprios podem ser colocados em `.runtime/server/mods/deathmatch/resources/`.

A conta `ruaan` recebe Admin/Console e, no primeiro login após a instalação dos benefícios, dinheiro de jogo, Cash e os veículos definidos em `owner-perks/server.lua`. O telefone é atribuído pelo próprio recurso do celular. O Console permite criar e administrar facções; facções já pertencentes a outros jogadores não são transferidas.

O pacote traz webhooks e tokens para APIs antigas de loja/logs, além de um serviço externo de recuperação de senha. Esses endpoints/credenciais foram desativados; a recuperação por e-mail e a integração de loja exigem serviços próprios. O banco antigo de contas foi limpo para que cada jogador crie uma conta nova.

O arquivo RAR original não foi alterado e contém essas credenciais antigas; revogue/rotacione-as nos serviços correspondentes. Ele está ignorado pelo Git para evitar publicar o arquivo e seus segredos por acidente.