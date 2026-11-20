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
NAVY = colors.black
GRAY = colors.HexColor('#555555')
W, H = A4

def paragraph(c, text, x, top, width, size=11, color=NAVY):
    style = ParagraphStyle('p', fontName='Times-Roman', fontSize=size, leading=size*1.4, textColor=color, splitLongWords=True)
    p = Paragraph(text, style)
    _, height = p.wrap(width, H)
    p.drawOn(c, x, top-height)
    return top-height

def footer(c, page, width=W, baseline=31):
    c.setFillColor(GRAY); c.setFont('Times-Roman', 9)
    c.drawRightString(width-48,baseline,str(page))

def generate(path, org='', video='', modelo=False, github='https://github.com/Wiclif06/GSCloud', video2=''):
    path = Path(path); path.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(path), pagesize=A4)
    c.setTitle('AgroConecta - Global Solution 2026/2 - RM563901')
    c.setAuthor('Felipe Wiclif Leal da Silva; Deryk de Souza Queiroz; Lucas Gonçalves Viana; Vinicius Paschoeto da Silva')
    c.setSubject('DevOps Tools & Cloud Computing - CitizenTech')
    c.setCreator('AgroConecta - Documentação técnica')
    c.setFillColor(colors.black)
    c.setFont('Times-Bold',14); c.drawCentredString(W/2,H-68,'FIAP - GLOBAL SOLUTION 2026/2')
    c.setFont('Times-Roman',12); c.drawCentredString(W/2,H-93,'DevOps Tools & Cloud Computing')
    c.setFont('Times-Bold',20); c.drawCentredString(W/2,H-151,'AgroConecta')
    y=H-200
    paragraph(c,'<b>Integrantes</b>',60,y,W-120,12)
    y-=34
    for name,rm in TEAM:
        c.setFont('Times-Roman',12); c.drawString(60,y,name)
        c.drawRightString(W-60,y,'RM '+rm)
        y-=25
    y-=13
    y-=52
    platform = lambda value: 'Google Drive' if urlparse(value).hostname == 'drive.google.com' else 'YouTube'
    links = [('Organização no Azure DevOps','azure_devops',org),('Repositório GitHub','github',github),('Vídeo 1 - '+platform(video),'video',video)]
    if video2:
        links.append(('Vídeo 2 - '+platform(video2),'video2',video2))
    for label,name,value in links:
        paragraph(c,'<b>'+label+'</b>',60,y,W-120,12)
        y-=25
        if modelo:
            c.acroForm.textfield(name=name, tooltip=label+' - informe o link real e salve o PDF',
                x=60,y=y-18,width=W-120,height=26,fontName='Times-Roman',fontSize=10,
                textColor=NAVY,borderColor=colors.HexColor('#9aafbc'),fillColor=colors.white,
                borderWidth=1,forceBorder=True,fieldFlags='required',value='')
            y-=53
        else:
            y=paragraph(c,'<link href="'+escape(value,{'"':'&quot;'})+'" color="#000080"><u>'+escape(value)+'</u></link>',60,y+4,W-120,11)-25
    footer(c,1); c.showPage()
    page_width,page_height=landscape(A4)
    c.setPageSize((page_width,page_height))
    c.setFillColor(colors.black);c.setFont('Times-Bold',14)
    c.drawString(48,page_height-29,'Arquitetura da solução - AgroConecta')
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
    youtube = b.hostname in {'youtube.com','www.youtube.com','youtu.be'} and re.fullmatch(r'[A-Za-z0-9_-]{11}',ident)
    drive = b.hostname == 'drive.google.com' and re.fullmatch(r'/file/d/[A-Za-z0-9_-]+/view',b.path)
    if b.scheme!='https' or not (youtube or drive):
        raise ValueError('Informe um link real do vídeo no YouTube ou Google Drive.')
    if any(s in (org+' '+video).lower() for s in ['sua_organizacao','exemplo','placeholder','url_real']):
        raise ValueError('Links de exemplo não podem ser usados na entrega.')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--org',help='URL real da organização Azure DevOps')
    parser.add_argument('--video',help='URL real do vídeo publicado no YouTube ou Google Drive')
    parser.add_argument('--video2',default='',help='URL opcional do segundo vídeo')
    parser.add_argument('--github',default='https://github.com/Wiclif06/GSCloud',help='URL do repositório GitHub')
    parser.add_argument('--modelo',action='store_true',help='Gerar apenas modelo preenchível sem links')
    parser.add_argument('--saida',type=Path)
    args=parser.parse_args()
    if not args.modelo:
        if not args.org or not args.video: parser.error('--org e --video são obrigatórios na entrega final.')
        try:
            validate(args.org,args.video)
            if args.video2: validate(args.org,args.video2)
        except ValueError as e: parser.error(str(e))
    target=args.saida or ROOT/'entrega'/'AgroConecta_rm563901.pdf'
    g=urlparse(args.github)
    if g.scheme!='https' or g.hostname!='github.com' or not re.fullmatch(r'/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/?',g.path):
        parser.error('--github deve ser a URL HTTPS de um repositório GitHub.')
    generate(target,args.org or '',args.video or '',args.modelo,args.github,args.video2)
    print(target.resolve())
