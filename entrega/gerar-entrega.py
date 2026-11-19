"""Gera a ficha PDF da disciplina. Requer Python 3 e reportlab."""
from pathlib import Path
from urllib.parse import urlparse, parse_qs
from xml.sax.saxutils import escape
import argparse
import re
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph

ROOT = Path(__file__).resolve().parents[1]
TEAM = [
    ('Felipe Wiclif Leal da Silva', '563901'),
    ('Deryk de Souza Queiroz', '563412'),
    ('Lucas Gonçalves Viana', '563254'),
    ('Vinicius Paschoeto da Silva', '563089'),
]
NAVY = colors.HexColor('#163047')
GREEN = colors.HexColor('#087f68')
GRAY = colors.HexColor('#526779')
W, H = A4

def paragraph(c, text, x, top, width, size=11, color=NAVY):
    style = ParagraphStyle('p', fontName='Helvetica', fontSize=size, leading=size*1.4, textColor=color, splitLongWords=True)
    p = Paragraph(text, style)
    _, height = p.wrap(width, H)
    p.drawOn(c, x, top-height)
    return top-height

def footer(c, page, width=W, baseline=31):
    c.setStrokeColor(colors.HexColor('#d5e0eb')); c.line(48, baseline+14, width-48, baseline+14)
    c.setFillColor(GRAY); c.setFont('Helvetica', 8)
    c.drawString(48, baseline, 'AgroConecta | Global Solution 2026/2 | RM563901')
    c.drawRightString(width-48,baseline,str(page))

def generate(path, org='', video='', modelo=False):
    path = Path(path); path.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(path), pagesize=A4)
    c.setTitle('AgroConecta - Global Solution 2026/2 - RM563901')
    c.setAuthor('Felipe Wiclif Leal da Silva; Deryk de Souza Queiroz; Lucas Gonçalves Viana; Vinicius Paschoeto da Silva')
    c.setSubject('DevOps Tools & Cloud Computing - CitizenTech')
    c.setCreator('AgroConecta - Documentação técnica')
    c.setFillColor(NAVY); c.rect(0,H-190,W,190,fill=1,stroke=0)
    c.setFillColor(colors.HexColor('#6de0bc')); c.setFont('Helvetica-Bold',10)
    c.drawString(48,H-53,'FIAP | GLOBAL SOLUTION 2026/2')
    c.setFillColor(colors.white); c.setFont('Helvetica-Bold',34); c.drawString(48,H-108,'AgroConecta')
    c.setFont('Helvetica',14); c.drawString(48,H-139,'DevOps Tools & Cloud Computing')
    c.setFont('Helvetica',11); c.drawString(48,H-164,'CitizenTech - Apoio inteligente ao pequeno produtor')
    y=H-228
    paragraph(c,'<b>Grupo AgroConecta</b>',48,y,W-96,17)
    y-=38
    paragraph(c,'Representante: Felipe Wiclif Leal da Silva | RM563901',48,y,W-96,11)
    y-=50
    for i,(name,rm) in enumerate(TEAM):
        c.setFillColor(colors.HexColor('#f0f5f8') if i%2==0 else colors.white)
        c.roundRect(48,y-32,W-96,36,5,fill=1,stroke=0)
        c.setFillColor(NAVY); c.setFont('Helvetica',11); c.drawString(60,y-18,name)
        c.setFont('Helvetica-Bold',10); c.drawRightString(W-60,y-18,'RM'+rm)
        y-=40
    y-=34
    for label,name,value in [('Organização no Azure DevOps','azure_devops',org),('Vídeo de demonstração no YouTube','youtube',video)]:
        paragraph(c,'<b>'+label+'</b>',48,y,W-96,11)
        y-=29
        if modelo:
            c.acroForm.textfield(name=name, tooltip=label+' - informe o link real e salve o PDF',
                x=48,y=y-18,width=W-96,height=26,fontName='Helvetica',fontSize=9,
                textColor=NAVY,borderColor=colors.HexColor('#9aafbc'),fillColor=colors.white,
                borderWidth=1,forceBorder=True,fieldFlags='required',value='')
            y-=53
        else:
            y=paragraph(c,'<link href="'+escape(value,{'"':'&quot;'})+'" color="#087f68">'+escape(value)+'</link>',48,y+4,W-96,10)-34
    footer(c,1); c.showPage()
    page_width,page_height=landscape(A4)
    c.setPageSize((page_width,page_height))
    c.setFillColor(NAVY);c.setFont('Helvetica-Bold',16)
    c.drawString(48,page_height-29,'AgroConecta | Arquitetura de implantação')
    image=ROOT/'docs/arquitetura-cloud.png'
    if image.exists():
        width=680; height=width*1220/1600
        c.drawImage(str(image),(page_width-width)/2,34,width=width,height=height,preserveAspectRatio=True,mask='auto')
    footer(c,2,width=page_width,baseline=13); c.save()
    return path

def validate(org,video):
    a=urlparse(org); b=urlparse(video)
    valid_org = a.scheme=='https' and ((a.hostname=='dev.azure.com' and re.fullmatch(r'/[A-Za-z0-9_-]+/?',a.path)) or (a.hostname or '').endswith('.visualstudio.com'))
    if not valid_org: raise ValueError('Informe a URL real da organização Azure DevOps com HTTPS.')
    ident = b.path.strip('/') if b.hostname=='youtu.be' else parse_qs(b.query).get('v',[''])[0]
    if b.scheme!='https' or b.hostname not in {'youtube.com','www.youtube.com','youtu.be'} or not re.fullmatch(r'[A-Za-z0-9_-]{11}',ident):
        raise ValueError('Informe o link real do vídeo: https://www.youtube.com/watch?v=ID ou https://youtu.be/ID.')
    if any(s in (org+' '+video).lower() for s in ['sua_organizacao','exemplo','placeholder','url_real']):
        raise ValueError('Links de exemplo não podem ser usados na entrega.')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--org',help='URL real da organização Azure DevOps')
    parser.add_argument('--video',help='URL real do vídeo publicado no YouTube')
    parser.add_argument('--modelo',action='store_true',help='Gerar apenas modelo preenchível sem links')
    parser.add_argument('--saida',type=Path)
    args=parser.parse_args()
    if not args.modelo:
        if not args.org or not args.video: parser.error('--org e --video são obrigatórios na entrega final.')
        try: validate(args.org,args.video)
        except ValueError as e: parser.error(str(e))
    target=args.saida or ROOT/'entrega'/'AgroConecta_rm563901.pdf'
    generate(target,args.org or '',args.video or '',args.modelo)
    print(target.resolve())
