/// Curated themed word lists for daily puzzles + infinite levels.
/// Each theme has 25-40 candidate goal words (3-9 letters). The generator
/// picks a subset that fits in the hex grid using shared letters.
///
/// With 20 themes × ~30 words = 600+ thematic candidates, the generator
/// rarely repeats the same goal trio across hundreds of levels.
class Themes {
  static const Map<String, List<String>> sets = {
    'Garden': [
      'rose','leaf','seed','vine','bloom','petal','stem','bud','grow','soil',
      'herb','moss','fern','bee','tulip','daisy','lily','iris','poppy','mint',
      'thyme','bush','root','sprout','garden','green','plant','sage','clover','weed',
      'pollen','spade','rake','shovel','pot','nectar','hose','beetle',
    ],
    'Ocean': [
      'wave','salt','reef','tide','coral','shell','crab','fish','kelp','foam',
      'sand','dive','swim','sail','ocean','beach','shark','pearl','squid','tuna',
      'whale','boat','anchor','marina','pier','buoy','algae','lagoon','seal','octopus',
      'eel','jelly','clam','starfish','dolphin','reefs','breeze','salty',
    ],
    'Space': [
      'star','moon','orbit','comet','solar','mars','sun','void','nova','dust',
      'ring','beam','cosmo','ray','planet','asteroid','rocket','venus','jupiter','saturn',
      'galaxy','nebula','quark','meteor','crater','probe','lunar','eclipse','telescope','astro',
      'mercury','pluto','neptune','spacex','milkyway','cosmic','warp','plasma',
    ],
    'Cozy': [
      'warm','tea','book','quilt','fire','soft','sip','rest','calm','knit',
      'glow','mug','sock','nap','blanket','candle','sweater','pillow','hearth','snug',
      'cocoa','mitten','cabin','pajama','slipper','snore','dream','hug','cuddle','smile',
      'lamp','curtain','rug','bath','steam','warmth',
    ],
    'Forest': [
      'tree','bark','leaf','fern','owl','fox','pine','oak','elk','deer',
      'wolf','moss','vine','log','trail','cedar','birch','maple','willow','redwood',
      'hawk','badger','rabbit','squirrel','toad','beaver','mushroom','acorn','twig','stump',
      'mosswood','grove','canopy','glade','ranger',
    ],
    'Bakery': [
      'bread','dough','flour','sugar','egg','butter','jam','tart','bun','roll',
      'cake','pie','oven','cup','muffin','cookie','scone','bagel','donut','pretzel',
      'pastry','cinnamon','vanilla','glaze','frosting','knead','yeast','crust','baker','crumb',
      'whisk','batter','rise','syrup','honey','sprinkle',
    ],
    'Storm': [
      'rain','wind','bolt','thunder','cloud','flash','gale','hail','mist','fog',
      'rumble','dark','storm','pour','tempest','typhoon','gust','torrent','drizzle','squall',
      'lightning','blizzard','flood','sleet','breeze','soaked','muddy','umbrella','poncho','damp',
      'shiver','swirl','funnel','front','barometer','overcast',
    ],
    'Citrus': [
      'lemon','lime','zest','peel','sour','juice','pulp','rind','tang','orange',
      'sunny','sweet','tart','sip','grapefruit','tangerine','clementine','mandarin','citron','kumquat',
      'yuzu','pomelo','squeeze','wedge','slice','marmalade','sorbet','lemonade','citrusy','sparkle',
      'fruit','vibrant','fresh','grove','harvest','seedy',
    ],
    'Music': [
      'note','tune','beat','song','chord','drum','bass','jazz','rock','pop',
      'blues','tempo','treble','melody','rhythm','piano','guitar','violin','flute','trumpet',
      'cello','clef','sharp','flat','octave','choir','vocal','album','remix','solo',
      'lyric','encore','bridge','verse','tour','band',
    ],
    'Sports': [
      'ball','goal','team','play','run','jump','race','win','game','kick',
      'pass','dunk','swim','bike','golf','tennis','soccer','rugby','hockey','cricket',
      'pitch','bat','glove','helmet','net','court','field','arena','medal','trophy',
      'rally','sprint','marathon','coach','referee','dribble',
    ],
    'Travel': [
      'trip','tour','road','map','plane','train','bus','taxi','hotel','beach',
      'visa','pack','suitcase','luggage','passport','flight','depart','arrive','tourist','journey',
      'cruise','safari','holiday','vacation','itinerary','hostel','resort','airport','station','jetlag',
      'roam','wander','souvenir','postcard','adventure','explore',
    ],
    'Food': [
      'rice','pasta','soup','salad','bread','meat','fish','curry','spice','herb',
      'sushi','pizza','burger','taco','noodle','sauce','grill','bake','fry','steam',
      'tomato','onion','garlic','pepper','cheese','olive','lemon','sweet','salty','crispy',
      'savory','tasty','dish','meal','feast','snack',
    ],
    'Animals': [
      'cat','dog','cow','pig','rat','horse','sheep','goat','duck','fox',
      'lion','tiger','bear','wolf','zebra','giraffe','monkey','panda','kangaroo','koala',
      'eagle','sparrow','owl','parrot','snake','frog','turtle','rabbit','hamster','dolphin',
      'shark','whale','elephant','rhino','hippo','camel',
    ],
    'Tech': [
      'data','code','byte','chip','app','web','file','link','cloud','server',
      'pixel','mouse','laptop','tablet','phone','router','wifi','python','dart','java',
      'github','docker','kernel','memory','screen','module','branch','commit','debug','script',
      'plugin','virtual','crypto','token','login','reboot',
    ],
    'Adventure': [
      'climb','dive','trek','hike','quest','dare','brave','wild','rope','peak',
      'cave','cliff','desert','jungle','river','rapid','summit','glacier','volcano','rapids',
      'compass','torch','tent','knapsack','machete','camp','expedition','explore','daring','risky',
      'roam','bold','epic','mystery','ranger','scout',
    ],
    'Color': [
      'red','blue','green','gold','pink','black','white','grey','brown','navy',
      'amber','azure','beige','cyan','coral','crimson','indigo','ivory','jade','khaki',
      'lemon','lilac','mauve','olive','peach','plum','ruby','rust','sand','tan',
      'teal','vivid','pastel','neon','silver','bronze',
    ],
    'School': [
      'book','pen','desk','test','math','grade','class','study','teach','learn',
      'history','science','english','algebra','biology','chemistry','geometry','spelling','recess','homework',
      'pencil','crayon','eraser','paper','folder','locker','library','professor','student','teacher',
      'lecture','exam','quiz','syllabus','course','subject',
    ],
    'Castle': [
      'king','queen','knight','sword','crown','tower','gate','moat','realm','royal',
      'castle','palace','dragon','wizard','jester','noble','manor','keep','court','throne',
      'shield','helm','armor','quest','sword','steed','herald','vassal','duke','baron',
      'fairy','magic','spell','potion','dungeon','feast',
    ],
    'Vehicles': [
      'car','bus','van','jet','ship','bike','boat','tram','cab','sled',
      'truck','train','plane','rocket','scooter','tractor','sedan','coupe','wagon','minivan',
      'helicopter','submarine','yacht','glider','blimp','engine','wheel','tire','horn','siren',
      'cabin','cockpit','rudder','sail','tank','convoy',
    ],
    'Weather': [
      'sun','rain','snow','wind','fog','ice','hot','cold','warm','cool',
      'humid','sunny','cloudy','foggy','rainy','snowy','windy','breezy','frosty','muggy',
      'sleet','hail','thunder','lightning','rainbow','heat','wave','cool','climate','season',
      'spring','summer','autumn','winter','forecast','barometer',
    ],
    'Fantasy': [
      'magic','spell','wizard','witch','fairy','elf','dwarf','troll','giant','dragon',
      'unicorn','phoenix','goblin','ogre','mermaid','potion','wand','rune','quest','realm',
      'enchant','curse','prophet','oracle','vampire','werewolf','sorcery','mythical','mystic','arcane',
      'glimmer','sparkle','crystal','amulet','talisman','sceptre',
    ],
  };

  static List<String> themeKeys() => sets.keys.toList();
}
