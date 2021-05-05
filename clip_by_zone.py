#!/usr/bin/python3
# -*- coding: utf-8 -*-
import os, sys, argparse 
from PIL import Image
from lxml import etree
#parse the arguments 
parser = argparse.ArgumentParser(description='Generate ocr training set from Lace CSV output') 
parser.add_argument('--imageDir',    action="append",
                   help='Path to directory where source images are found',
                    required=True)
parser.add_argument('--outputDir', default='Cropped_zones_images',
                   help='Path to directory where output is stored')
parser.add_argument('--svgDir', help='Path to directory where SVGs are stored', required=True,
                    action="append")
parser.add_argument("-v", "--verbose", help="increase output verbosity",
                    default=False,
                    action="store_true")
parser.add_argument("--format", type=str, choices=["jpg", "png", "tif"],
                    default="png",
                    help="set the format of the output images"),
parser.add_argument("--zone", type=str, default='primary_text', choices=["primary_text", "translation", "commentary"],
                    help="the id of the zone(s) to be preserved in the original images")
parser.add_argument("--rightRemove", type=int, default=0,
                    help="amount to subtract from the right margin")
args = parser.parse_args()

#Check that the images directories actually exist
for image_dir in args.imageDir:
    if not(os.path.isdir(image_dir)):
           print('Image directory "'+image_dir+'" does not exist.\n\tExiting ...')
           sys.exit(1)

svg_dir = args.svgDir[0]
#Check that the svg directory actually exists
if not(os.path.isdir(svg_dir)):
    print('SVG dir"'+svg_dir+'" does not exist.\n\tExiting ...')
    sys.exit(1)
#Create the output directory if it doesn't exist
try:
    if not os.path.exists(args.outputDir):
        os.makedirs(args.outputDir, exist_ok=True)
except Exception as e:
    print("Error on creating output directory '" + args.outputDir + "':\n\t" +
          str(e) + "\n\tExiting ...")
    sys.exit(1)

if (args.verbose):
    print("Image dir(s):", args.imageDir)
    print("Output dir:", args.outputDir)
    print("SVG dir:", svg_dir)


for filename in os.listdir(svg_dir):
    if not(filename.endswith(".svg")):
        continue
    else:
        #check there is a corresponding image file
        basename = os.path.splitext(filename)[0]
        image_filename = basename + ".png"
        image_filepath = os.path.join(image_dir,image_filename)
        if not(os.path.exists(image_filepath)):
            print("Warning: there is no image file corresponding to filename '", filename, "'")
            sys.exit(1)
        else:
            if (args.verbose):
                print("\nNew svg image pair:", filename, ", ", image_filename)
            img = Image.open(image_filepath)
            image_width, image_height = img.size
            image_out = Image.new("1",img.size,color=255)
            if (args.verbose):
                print(img.size)
            tree = etree.parse(open(os.path.join(svg_dir,filename)))
            if (args.verbose):
                print(etree.tostring(tree))
            svg_namespace = {'svg': 'http://www.w3.org/2000/svg'}
            svg_width = float(tree.xpath('/svg:svg/@width', namespaces=svg_namespace)[0])
            svg_height = float(tree.xpath('/svg:svg/@height', namespaces=svg_namespace)[0])
            hz_scale = image_width / svg_width
            vertical_scale = image_height / svg_height
            if (args.verbose):
                print("svg dimensions:", svg_width, svg_height)
                print("hz scale: ", hz_scale)
                print("vertical scale: ", vertical_scale)
            #check that the scales are the same, roughly?
            scale = hz_scale
            primary_text_zone_rects = tree.xpath('//svg:rect[@data-rectangle-type="'+args.zone+'"]', namespaces=svg_namespace)
            for primary_text_zone_rect in primary_text_zone_rects:
                if (args.verbose):
                    print(etree.tostring(primary_text_zone_rect))
                try:
                    rect_x = float(primary_text_zone_rect.get("x"))
                    rect_y = float(primary_text_zone_rect.get("y"))
                    rect_height = float(primary_text_zone_rect.get("height"))
                    rect_width = float(primary_text_zone_rect.get("width")) - args.rightRemove
                    if (args.verbose):
                        print("a " + args.zone + " rect: ", rect_x, rect_y, rect_height, rect_width)
                except:
                    print("fail to parse the following primary text zone:", etree.tostring(primary_text_zone_rect))
                    continue
                left_int = int(rect_x * scale)
                upper_int = int(rect_y * scale)
                right_int = left_int + int(rect_width * scale)
                lower_int = upper_int + int(rect_height * scale)
                crop_box = (left_int, upper_int, right_int, lower_int)
                cropped_region = img.crop(box=crop_box)
                image_out.paste(cropped_region,box=crop_box)
            image_out.save(os.path.join(args.outputDir,image_filename))                

