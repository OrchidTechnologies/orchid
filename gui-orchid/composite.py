#!/usr/bin/python3

import itertools
import re
import os
import csv
import json
import logging
import sys

magickpath = ' '.join(sys.argv[1:])

logging.basicConfig(level="DEBUG", format='%(asctime)s: %(message)s')

def prepargs(cmd):
   rex = re.compile(r'\s+')
   return rex.sub(' ', cmd.replace('\n','').replace("(","'('").replace(")","')'"))

def collapse(str):
   rex = re.compile(r'\s+')
   return rex.sub(' ', str.replace('\n', ' '))

def resolution(img):
   code, result = exec(f'{magickpath} identify {img}')
   return result.split(' ')[2].split('x')

def convert(args, dst, ftype='PNG32'):
   cmd = f'{magickpath} convert {prepargs(args)} {ftype}:{dst}'
   return cmd

def exec(cmd):
   logging.debug(f'Executing: {cmd}')
   stream = os.popen(cmd)
   result = stream.read()
   code = stream.close()
   if code != None and code != 0:
      logging.debug(f'Executing: {cmd}')
      logging.debug(f'Return code: {code}')
      assert(false)
   return code, result


with open('/'.join(os.path.realpath(__file__).split('/')[0:-1]) + '/composite_worklist.json') as f:
   worklist = json.loads(f.read())

mocks = worklist['device_mocks']
messages = worklist['messages']
imagesets = worklist['imagesets']
fontsets = worklist['fontsets']

def distort(img, t1, t2, t3, t4, twidth, theight):
   width, height = resolution(img)
   s1 = "0,0"
   s2 = f"0,{height}"
   s3 = f"{width},{height}"
   s4 = f"{width},0"
   out = f"""-size {twidth}x{theight} xc:transparent ( {img} -virtual-pixel transparent -alpha set -background none
              +distort Perspective '{s1} {t1} {s2} {t2} {s3} {t3} {s4} {t4}' ) -flatten"""
   return collapse(out)

def mockup(template_name=None, screencap=None, placement=None, language='en'):
   logging.debug(f"mockup(template_name={template_name}, screencap={screencap}, placement={placement}, language={language})")
   template = mocks[template_name]
   t1, t2, t3, t4 = template['distort_to']
   bezel = f'bezel/{template_name}.png'
   bezw, bezh = resolution(bezel)
   mask = f'mask/{template_name}.png'
   maskw, maskh = resolution(mask)
   cap = screencap.replace('%lang%', language)
   cap_ = cap.rsplit('/', 1)[-1]
   workdir = 'work/'

   distfile = workdir + '_distorted.'.join(cap_.rsplit('.', 1))
   distcmd = convert(distort(cap, *template['distort_to'], maskw, maskh), distfile)

   maskfile = workdir + '_masked.'.join(cap_.rsplit('.', 1))
   maskcmd = convert(f"""{distfile} {mask} -alpha Off -compose CopyOpacity -composite""", maskfile)

   bezfile = workdir + '_bezel.'.join(cap_.rsplit('.', 1))
   bezcmd = convert(f'-background transparent {bezel} {maskfile} -page +0+0 -composite ', bezfile)

   return [[distcmd, maskcmd, bezcmd], bezfile]

def annotation(message=None, size=None, style='default', fontset='default', location=None, language='en', text=None):
   fontset = fontsets[fontset]
   font = fontset[language]
   langstyle = f'{style}_{language}'
   if langstyle in fontset['styles']:
      style_ = fontset['styles'][langstyle]
   else:
      style_ = fontset['styles'][style]
   return collapse(f"""( -size {size} -background transparent -gravity center -font {font} {style_}
                -annotate {location} "{text}" )""")

for setname, set in imagesets.items():
#   if setname != 'play_store': # and setname != 'app_store_ios':
#      continue
   logging.info(f'Starting image set {setname}')
#   set['languages'] = ['tr']
   for language in set['languages']:
      for imgname, imgspec in set['images'].items():
         logging.debug(imgspec)
#         if imgname != 'android_feature_1024x500':
#            continue
         try:
            os.mkdir(f'final', 0o755)
         except:
            pass
         try:
            os.mkdir(f'final/{setname}', 0o755)
         except:
            pass
         try:
            os.mkdir(f'final/{setname}/{language}', 0o755)
         except:
            pass
         dest = f'final/{setname}/{language}/{imgname}.png'
         logging.info(f'   {dest}')
#         res = imgspec['resolution']
         bg = imgspec['background']
         comp = None

         notes = []
         note_txt = ''
         if 'annotation' in imgspec:
            notes.append(annotation(**imgspec['annotation'], language=language, text=messages[imgspec['annotation']['message']][language]))
         if 'annotations' in imgspec:
            for a in imgspec['annotations']:
               notes.append(annotation(**a, language=language, text=messages[a['message']][language]))
         note_txt = ' -flatten '.join(notes)

         mocklist = []
         mock_txt = ''
         if 'mock' in imgspec:
            mocklist.append(imgspec['mock'])
         if 'mocks' in imgspec:
            mocklist = mocklist + imgspec['mocks']

         for m in mocklist:
            mockcmds, mockfile = mockup(**m, language=language)
            for x in mockcmds:
               exec(x)
            mock_txt = mock_txt + f" ( {mockfile} {m['placement']} ) -composite"

         gfx_txt = ''
         if 'graphic' in imgspec:
            gfx = imgspec['graphic']
            gfx_txt = f"( {gfx['file']} {gfx['placement']} ) -composite"

         exec(convert(f"( bg/{bg} -gravity center {gfx_txt} {mock_txt} ) {note_txt} -layers flatten -alpha off", dest))
