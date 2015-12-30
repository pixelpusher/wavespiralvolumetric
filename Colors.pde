import toxi.color.ColorList;
import toxi.color.TColor;
import toxi.color.ColorRange;
import toxi.color.ColorTheme;
import toxi.color.ColorGradient;

ArrayList<TColor> GraphColors = new ArrayList<TColor>();

// graph colors
TColor waveDataColor, RMSColor, RMSVelColor;

// helix colors
TColor helixStartColor, helixEndColor, helixStrokeColor;
ColorTheme helixColorTheme;
ColorGradient helixColorGrad;
ColorList helixColors;

void setupColors()
{
  waveDataColor = TColor.newRGBA(76,204,20,165); // doesn't work for fill??
  RMSColor = TColor.newRGBA(105,64,255,255);
  RMSVelColor = TColor.newRGBA(20,30,204,255);
  
  helixStrokeColor = TColor.newRGB(52,102,100);
  
  helixStartColor = TColor.newRGB(0,229,219);
  helixEndColor= TColor.newRGB(211,255,253);
  
  helixColorTheme = new ColorTheme("helix");
  
  helixColorGrad = new ColorGradient();
  
  helixColorTheme.addRange(ColorRange.BRIGHT, helixStartColor, 0.5);
  helixColorTheme.addRange(ColorRange.DARK, helixEndColor, 0.5);

  //helixColorGrad.addColorAt(0, helixStartColor);
  //helixColorGrad.addColorAt(100, helixEndColor);
  //helixColors = helixColorGrad.calcGradient(0,width);

  //helixColors = helixColorTheme.getColors(100).sortByDistance(false);
}
