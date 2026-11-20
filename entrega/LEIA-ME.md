# PDF para o Portal do Aluno

AgroConecta_rm563901.pdf contém o grupo, nomes e RMs dos quatro integrantes, organização Azure DevOps, GitHub, link da gravação e arquitetura.

- Organização: https://dev.azure.com/RM563254/
- GitHub: https://github.com/Wiclif06/GSCloud
- Vídeo fornecido pela equipe: https://drive.google.com/file/d/1rYF8QrBoP4zz8mvWbLlZNkwOMcHOt96-/view?usp=sharing

O PDF usa o link do Google Drive solicitado pela equipe. O enunciado especifica YouTube; a disponibilidade no Drive não confirma aceitação dessa substituição pelo professor.

Para gerar a versão definitiva com os dois links, execute na raiz do projeto:

```powershell
python -m pip install reportlab
$video = Read-Host 'Link real do vídeo de Cloud no YouTube ou Google Drive'
python entrega/gerar-entrega.py --org https://dev.azure.com/RM563254/ --github https://github.com/Wiclif06/GSCloud --video $video
```

Após qualquer atualização, reabra o PDF e confira os três links e a disponibilidade da gravação. A atividade de Cloud solicita o PDF, com nome do grupo e RM do representante; o ZIP é material de trabalho. Os recursos e o projeto privado no Azure devem permanecer acessíveis ao professor.
