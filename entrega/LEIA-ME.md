# PDF para o Portal do Aluno

AgroConecta_rm563901.pdf contém o grupo, nomes e RMs dos quatro integrantes, organização Azure DevOps, GitHub, links dos dois vídeos e arquitetura.

- Organização: https://dev.azure.com/RM563254/
- GitHub: https://github.com/Wiclif06/GSCloud
- Vídeo 1 - YouTube: https://youtu.be/AKYmF_mgBQ8
- Vídeo 2 - Google Drive: https://drive.google.com/file/d/1rYF8QrBoP4zz8mvWbLlZNkwOMcHOt96-/view?usp=sharing

Os vídeos estão identificados na ordem solicitada pela equipe: YouTube como Vídeo 1 e Google Drive como Vídeo 2.

Para gerar novamente o PDF, execute na raiz do projeto:

```powershell
python -m pip install reportlab
python entrega/gerar-entrega.py --org https://dev.azure.com/RM563254/ --github https://github.com/Wiclif06/GSCloud --video 'https://youtu.be/AKYmF_mgBQ8' --video2 'https://drive.google.com/file/d/1rYF8QrBoP4zz8mvWbLlZNkwOMcHOt96-/view?usp=sharing'
```

Após qualquer atualização, reabra o PDF e confira os quatro links e a disponibilidade dos vídeos. A atividade de Cloud solicita o PDF, com nome do grupo e RM do representante; o ZIP é material de trabalho. Os recursos e o projeto privado no Azure devem permanecer acessíveis ao professor.
