# PDF para o Portal do Aluno

AgroConecta_rm563901.pdf contém o grupo, os quatro integrantes e a arquitetura. A organização https://dev.azure.com/RM563254/ já está preenchida e possui link clicável. Apenas o campo do vídeo está vazio, para receber o endereço real depois da gravação e publicação no YouTube.

Para gerar a versão definitiva com os dois links, execute na raiz do projeto:

```powershell
python -m pip install reportlab
$video = Read-Host 'Link real do vídeo de Cloud no YouTube'
python entrega/gerar-entrega.py --org https://dev.azure.com/RM563254/ --video $video
```

Alternativamente, preencha o campo do vídeo em um leitor que salve formulários e reabra o PDF para conferir. O vídeo precisa ser acessível ao professor. Não envie o PDF com esse campo vazio. A atividade de Cloud solicita o PDF, com nome do grupo e RM do representante; o ZIP é material de trabalho.
