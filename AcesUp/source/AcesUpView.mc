import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Application.Storage;
import Toybox.Timer;

var DS = System.getDeviceSettings();
var SW = DS.screenWidth;
var SH = DS.screenHeight;
var centerX = SW/2;
var centerY = SH/2;
var center = Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER;
var left = Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER;
var right = Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER;

var game,state,deck,stack,wild,wilds,rems;
var gamehist,lastgame,stats;
var titleXY,wildslabelXY,resultXY;
var bgXY,bgWH,themeXY,themeWH,suitsXY,suitsWH,sampcardXY,sampwildXY;
var wildsXY,wildsWH,startXY,startWH;
var stackXY,deckXY,wildXY,cardWH,cardR;
var undoXY,undoWH,newXY,newWH,buttonR;
var solid,shadow,so,soh,overlap;
var mydc,tmp,tmp2,tmp3,tmp4;
var wilding,moving,dealing,path,timer,offscreen,juststarted;
var bigfont = Graphics.FONT_SMALL;
var smallfont = Graphics.FONT_TINY;
var buttonfont = Graphics.FONT_TINY;
var histlimit = 9999;

var themes = ["Outlines", "Outlines with shadows", "Solids", "Solids with shadows"];
var theme = 3;
var suitcolors = ["Standard", "Four Colors"];
var suitcolor = 0;
var backgrounds = ["Green", "Blue", "Red", "Black"];
var bgcolors = [0x204020, 0x006374, 0x7f2019, 0x000000];
var background = 0;
var animations = ["Normal", "Fast", "Super Fast"];
var animation = 0;

var titlecolor = 0xf4c223;
var buttoncolor = 0x56bfec;
var wildslabelcolor = 0xe6e3de;
var wildscolor = 0xec8871;
var wildcolor = 0xec8871;
var startcolor = 0xf4c223;
var wincolor = 0x27c235;
var losecolor = 0xcc5c5c;
var newcolor = 0xf4c223;
var selcolor = 0xf4c223;
var undocolor = 0x56bfec;
var deckcolor = 0x56bfec;
var scolors,ocolors;
var backcolor = 0xe6e3de;
var bgcolor;
// grays
var valcolor = 0xaaaaaa;
var shadowcolor = 0x555555;
var nopecolor = 0x808080;

var suitF,suitH,suitA,suitD;

class AcesUpView extends WatchUi.View {

    function initialize() {
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        cardWH = [SW*12/100,SH*18/100];
        cardR = cardWH[0]*12/100;
        buttonR = cardR*2;
        offscreen = [SW/2,SH+cardWH[1]];
        moving = false;

        so = SW*1/100;
        soh = so/2;

        // All XY values are centers
        // State 0 locations
        titleXY = [SW/2,SH*12/100];

        sampcardXY = [
            [SW*30/100,SH*30/100],
            [SW*30/100,SH*40/100],
            [SW*50/100,SH*30/100],
            [SW*50/100,SH*40/100],
        ];
        sampwildXY = [
            [SW*70/100,SH*30/100],
            [SW*70/100,SH*35/100],
            [SW*70/100,SH*40/100],
        ];

        themeXY = [SW*18/100,SH*60/100];
        themeWH = [SW*30/100,SH*13/100];
        suitsXY = [SW*50/100,SH*60/100];
        suitsWH = [SW*30/100,SH*13/100];
        wildsXY = [SW*82/100,SH*60/100];
        wildsWH = [SW*30/100,SH*13/100];

        bgXY = [SW/2,SH*75/100];
        bgWH = [SW*60/100,SH*13/100];

        startXY = [SW/2,SH*90/100];
        startWH = [SW*30/100,SH*13/100];

        // State 1+ locations
        stackXY = [
            [SW*20/100,SH*25/100],
            [SW*34/100,SH*25/100],
            [SW*48/100,SH*25/100],
            [SW*62/100,SH*25/100],
        ];
        deckXY = [SW*80/100,SH*25/100];
        wildXY = [SW*80/100,SH*47/100];
        resultXY = [SW/2,SH*70/100];
        undoXY = [SW*35/100,SH*83/100];
        undoWH = [SW*28/100,SH*13/100];
        newXY = [SW*65/100,SH*83/100];
        newWH = [SW*28/100,SH*13/100];

        calcoverlap(-1);
        wilding = false;
        moving = false;
        juststarted = false;
        path = [];

        // Load card font based on screen size
        if (SW < 270) { 
            suitF = WatchUi.loadResource(Rez.Fonts.suits20);
//            sh = 5;
        }
        else if (SW < 360) { 
            suitF = WatchUi.loadResource(Rez.Fonts.suits30); 
//            sh = 8;
        }
        else if (SW < 390) { 
            suitF = WatchUi.loadResource(Rez.Fonts.suits35); 
//            sh = 9;
        }
        else {
            suitF = WatchUi.loadResource(Rez.Fonts.suits40);
//            sh = 12;
        }
        suitH = Graphics.getFontHeight(suitF);
        suitA = suitH*29/100;
        suitD = suitH*42/100;
        if (System.getSystemStats().totalMemory < 700000) {
            histlimit = 10;
        }
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        mydc = dc;

        theme = Storage.getValue("theme");
        if (theme == null) { theme = 3; Storage.setValue("theme",theme); }
        switch (theme) {
            case 0:
                solid = false;
                shadow = false;
                break;
            case 1:
                solid = false;
                shadow = true;
                break;
            case 2:
                solid = true;
                shadow = false;
                break;
            case 3:
                solid = true;
                shadow = true;
                break;
        }

        background = Storage.getValue("background");
        if (background == null) { background = 0; Storage.setValue("background",background); }
        bgcolor = bgcolors[background];
        mydc.setColor(bgcolor,bgcolor);
        mydc.clear();

        animation = Storage.getValue("animation");
        if (animation == null) { animation = 0; Storage.setValue("animation",animation); }

        suitcolor = Storage.getValue("suitcolor");
        if (suitcolor == null) { suitcolor = 0; Storage.setValue("suitcolor",suitcolor); }
        // spades, clubs, diamonds, hearts
        switch (suitcolor) {
            case 0:
                scolors = [0x202020, 0x202020, 0xbe4b4b, 0xbe4b4b];
                ocolors = [0xffffff, 0xffffff, 0xbe4b4b, 0xbe4b4b];
                break;
            case 1:
                scolors = [0x202020, 0x33ac30, 0x5855fe, 0xbe4b4b];
                ocolors = [0xffffff, 0x33ac30, 0x5855fe, 0xbe4b4b];
                break;
        }

        // Load game
        if (!moving) {
            loadgame();
        }
        state = game.get("state");
        deck = game.get("deck");
        stack = game.get("stack");
        wild = game.get("wild");
        wilds = game.get("wilds");
        rems = game.get("rems");

        switch (state) {
            case 0:
                // New round
                // Select options (wilds, ?)
                drawlabel(titleXY,"Aces Up!",titlecolor,true,false);

                drawcard(sampcardXY[0], "As", false);
                drawcard(sampcardXY[1], "Ac", false);
                drawcard(sampcardXY[2], "Ah", false);
                drawcard(sampcardXY[3], "Ad", false);
                for (var i=0;i<wilds;i++) {
                    drawcard(sampwildXY[i], "W", false);
                }

                drawbutton(themeXY,themeWH,"Theme",buttoncolor,true);
                drawbutton(suitsXY,suitsWH,"Suits",buttoncolor,true);
                drawbutton(wildsXY,wildsWH,"Wilds",buttoncolor,true);

                drawbutton(bgXY,bgWH,"Background",buttoncolor,true);

                drawbutton(startXY,startWH,"Start",startcolor,true);
                break;
            case 1:
                // tap deck to draw
                // tap a card to select it
                // tap a stack to try to clear the bottom card (if not an ace) or move it to an empty stack
                // tap the wild stack to select it, then tapping a stack removes the bottom card (unless it's an ace)
                // so if doing that, highlight the bottom wild
                drawcards(deckXY,[deck.size()/4],false);
                for (var i=0;i<stack.size();i++) {
                    calcoverlap(i);
                    drawcards(stackXY[i],stack[i],true);
                }
                calcoverlap(-1);
                drawcards(wildXY,wild,true);
                drawbutton(undoXY,undoWH,"Undo",undocolor,gamehist.size() > 0);
                drawbutton(newXY,newWH,"New",newcolor,true);
                break;
            case 2:
                // No more moves, but user can undo and keep trying
                drawcards(deckXY,[deck.size()/4],false);
                for (var i=0;i<stack.size();i++) {
                    calcoverlap(i);
                    drawcards(stackXY[i],stack[i],true);
                }
                calcoverlap(-1);
                drawcards(wildXY,wild,true);
                tmp = losecolor;
                drawlabel(resultXY,"Out of Moves",tmp,true,true);
                drawbutton(undoXY,undoWH,"Undo",undocolor,gamehist.size() > 0);
                drawbutton(newXY,newWH,"New",newcolor,true);
                break;
            case 3:

// To do: no more moves check
//        animations of card movements (movecard, rem, and the case where ace is drawn and moves to the top of the stack)
// paths array: each entry has the stack of cards to move, the destination stack index (-1 for off screen), and the array of coordinates

                // Game won
                drawcards(deckXY,[deck.size()/4],false);
                for (var i=0;i<stack.size();i++) {
                    calcoverlap(i);
                    drawcards(stackXY[i],stack[i],true);
                }
                calcoverlap(-1);
                drawcards(wildXY,wild,true);
                drawlabel(resultXY,"You won!",wincolor,true,false);
                drawbutton(startXY,startWH,"New",newcolor,true);
                break;
        }

        if (moving) {
            var lastmove = true;
            for (var i=0;i<path.size();i++) {
                tmp = path[i][2];
                if (tmp.size() > 0) {
                    if (tmp.size() == 1) {
                        tmp2 = path[i][1];
                        if (tmp2 == -1) {
                            // add card to wild stack
                            wild.add(path[i][0]);
                        } else if (tmp2 != -2) {
                            // add card to stack tmp2
                            stack[tmp2].add(path[i][0]);
                        }
                    } else {
                        lastmove = false;
                    } 
                    path[i][2] = path[i][2].slice(1,null);
                    tmp = tmp[0];
                    drawcard(tmp,path[i][0],false);
                }
            }
            if (lastmove) {
                if (dealing) {
                    dealing = false;
                    for (var i=0;i<4;i++) {
                        if (path[i][0].substring(0,1).equals("A")) {
                            // Move the ace to the top
                            tmp = stack[i].size();
                            if (tmp > 1) {
                                calcoverlap(i);
                                for (var j=0;j<tmp-1;j++) {
                                    tmp2 = [stackXY[i][0],stackXY[i][1]+j*overlap];
                                    tmp3 = [stackXY[i][0],stackXY[i][1]+(j+2)*overlap];
                                    tmp4 = [stackXY[i][0],stackXY[i][1]+(j+1)*overlap];
                                    path.add([stack[i][j],i,calcpath(tmp2,tmp3).addAll(calcpath(tmp3,tmp4))]);
                                }
                                tmp2 = [stackXY[i][0],stackXY[i][1]+tmp*overlap];
                                tmp3 = stackXY[i];
                                path.add([stack[i][tmp-1],i,calcpath(tmp2,tmp3)]);
                                stack[i] = [];
                            }
                        }
                    }
                } else {
                    savegame(!juststarted);
                    juststarted = false;
                    moving = false;
                    path = [];
                }
            }
            timer = new Timer.Timer();
            timer.start(method(:onTimer), 50, false);
        }

    }

    function onTimer() as Void {
        WatchUi.requestUpdate();
    }

    function drawlabel(xy,text,col,big,bg) {
        if (bg) {
            mydc.setColor(bgcolor,-1);
            mydc.fillRoundedRectangle(0, xy[1]-SH*6/100, SW, SW*12/100, buttonR);
        }
        if (big) { tmp = bigfont; }
        else { tmp = smallfont; }
        if (shadow) {
            mydc.setColor(Graphics.COLOR_DK_GRAY,-1);
            mydc.drawText(xy[0]+so, xy[1]+so, tmp, text, center);
        }
        mydc.setColor(col,-1);
        mydc.drawText(xy[0], xy[1], tmp, text, center);
    }

    function drawbutton(xy,wh,text,col,valid) {
        var x = xy[0]-wh[0]/2;
        var y = xy[1]-wh[1]/2;
        var w = wh[0];
        var h = wh[1];
        if (solid) {
            if (shadow) {
                mydc.setColor(shadowcolor,-1);
                mydc.fillRoundedRectangle(x+so, y+so, w, h, buttonR);
            }
            if (valid) {
                mydc.setColor(col,-1);
            } else {
                mydc.setColor(nopecolor,-1);
            }
            mydc.fillRoundedRectangle(x, y, w, h, buttonR);
            if (shadow) {
                mydc.setColor(Graphics.COLOR_LT_GRAY,-1);
                mydc.drawText(xy[0]-soh, xy[1]-soh, buttonfont, text, center);
            }
            mydc.setColor(Graphics.COLOR_BLACK,-1);
            mydc.drawText(xy[0], xy[1], buttonfont, text, center);
        } else {
            if (shadow) {
                mydc.setColor(shadowcolor,-1);
                mydc.drawRoundedRectangle(x+so, y+so, w, h, buttonR);
                mydc.drawText(xy[0]+so, xy[1]+so, buttonfont, text, center);
            }
            if (valid) {
                mydc.setColor(col,-1);
            } else {
                mydc.setColor(nopecolor,-1);
            }
            mydc.drawRoundedRectangle(x, y, w, h, buttonR);
            mydc.drawText(xy[0], xy[1], buttonfont, text, center);
        }

    }

    function drawcards(xy, cards,sel) {
        if (cards.size() == 0) {
            drawcard(xy,"",false);
        } else {
            for (var i=0;i<cards.size();i++) {
                drawcard([xy[0],xy[1]+i*overlap], cards[i], sel and (i == cards.size()-1));
            }
        }
    }

    function drawcard(xy, card, sel) {
        var w = cardWH[0];
        var h = cardWH[1];
        var x = xy[0]-w/2;
        var y = xy[1]-h/2;
        var fc,tc;
        var l1 = "";
        var l2 = "";
        var other = false;
        card = card.toString();
        if (card.length() == 2) {
            l1 = card.substring(0,1);
            l2 = card.substring(1,2);
        } else {
            l1 = card;
        }
        if (sel and (!(wilding) or !(l1.equals("W") or !l1.equals("A")))) {
            sel = false;
        }
        switch (l2) {
            case "s":
                fc = backcolor;
                if (solid) { tc = scolors[0]; }
                else { tc = ocolors[0]; }
                break;
            case "c":
                fc = backcolor;
                if (solid) { tc = scolors[1]; }
                else { tc = ocolors[1]; }
                break;
            case "d":
                fc = backcolor;
                if (solid) { tc = scolors[2]; }
                else { tc = ocolors[2]; }
                break;
            case "h":
                fc = backcolor;
                if (solid) { tc = scolors[3]; }
                else { tc = ocolors[3]; }
                break;
            default:
                other = true;
                if (l1.length() == 0) {
                    // empty slot
                    fc = Graphics.COLOR_WHITE;
                    tc = Graphics.COLOR_BLACK;
                } else if (l1.equals("W")) {
                    // Wild card
                    fc = wildcolor;
                    if (solid) { tc = Graphics.COLOR_BLACK; }
                    else { tc = Graphics.COLOR_WHITE; }
                } else {
                    fc = deckcolor;
                    if (solid) { tc = Graphics.COLOR_BLACK; }
                    else { tc = Graphics.COLOR_WHITE; }
                }
                break;
        }

        // Draw card shape
        if (solid and l1.length() > 0) {
            if (shadow) {
                mydc.setColor(shadowcolor,-1);
                mydc.fillRoundedRectangle(x+so, y+so, w, h, cardR);
            }
            mydc.setColor(fc,-1);
            mydc.fillRoundedRectangle(x, y, w, h, cardR);
            mydc.setColor(Graphics.COLOR_DK_GRAY,-1);
            mydc.setPenWidth(2);
            mydc.drawRoundedRectangle(x, y, w, h, cardR);
            if (shadow) {
                mydc.setColor(Graphics.COLOR_LT_GRAY,-1);
            }
            mydc.setColor(tc,-1);
        } else {
            mydc.setPenWidth(2);
            mydc.setColor(bgcolor,-1);
            mydc.fillRoundedRectangle(x,y,w,h,cardR);
            if (shadow) {
                mydc.setColor(shadowcolor,-1);
                mydc.drawRoundedRectangle(x+so, y+so, w, h, cardR);
            }
            if (sel) {
                mydc.setColor(selcolor,-1);
            } else {
                mydc.setColor(fc,-1);
            }
            mydc.drawRoundedRectangle(x, y, w, h, cardR);
        }
        if (sel) {
            mydc.setColor(selcolor,-1);
            mydc.setPenWidth(4);
            mydc.drawRoundedRectangle(x, y, w, h, cardR);
        }

        // Draw card value
        if (other) {
            if (shadow) {
                if (solid) {
                    mydc.setColor(Graphics.COLOR_LT_GRAY,-1);
                } else {
                    mydc.setColor(shadowcolor,-1);
                }
                mydc.drawText(xy[0]+soh,xy[1]+soh,smallfont,card,center);
            }
            mydc.setColor(tc,-1);
            mydc.drawText(xy[0],xy[1],smallfont,card,center);
        } else {
            // top left, side by side
            // bottom right, side by side, reverse order?
            var rev = l2+l1;
            if (shadow) {
                if (solid) {
                    mydc.setColor(Graphics.COLOR_LT_GRAY,-1);
                } else {
                    mydc.setColor(shadowcolor,-1);
                }
                mydc.drawText(x+3+soh,y+1+suitA+soh,suitF,card,left);
                mydc.drawText(x+w-3+soh,y+h-1-suitD+soh,suitF,rev,right);
            }
            mydc.setColor(tc,-1);
            mydc.drawText(x+3,y+1+suitA,suitF,card,left);
            mydc.drawText(x+w-3,y+h-1-suitD,suitF,rev,right);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}

function newgame() {
    state = 0;
    deck = ["As","2s","3s","4s","5s","6s","7s","8s","9s","Ts","Js","Qs","Ks",
            "Ac","2c","3c","4c","5c","6c","7c","8c","9c","Tc","Jc","Qc","Kc",
            "Ad","2d","3d","4d","5d","6d","7d","8d","9d","Td","Jd","Qd","Kd",
            "Ah","2h","3h","4h","5h","6h","7h","8h","9h","Th","Jh","Qh","Kh"];
    for (var i=0;i<1000;i++) {
        tmp = Math.rand() % 52;
        tmp2 = Math.rand() % 52;
        tmp3 = deck[tmp];
        deck[tmp] = deck[tmp2];
        deck[tmp2] = tmp3;
    }
    stack = [[],[],[],[]];
    wild = [];
    rems = 0;
    gamehist = [];
    Storage.setValue("gamehist",gamehist);
    savegame(false);
}

function savegame(hist) as Void {
    if (hist) {
        gamehist = Storage.getValue("gamehist");
        if (gamehist.size() >= histlimit) {
            gamehist = gamehist.slice(1,null);
        }
        gamehist.add(deepcopy(lastgame));
        Storage.setValue("gamehist",gamehist);
        if (deck.size() == 0 ) {
            // Possibly end of game
            if (stack[0].size() == 1 and stack[1].size() == 1 and stack[2].size() == 1 and stack[3].size() == 1) {

                // Game won
                state = 3;
            } else {
                // See if any moves left (no wilds, and no bottom stack can play anywhere)
                // If no moves left, set state to 2
                tmp = false;
                if (wild.size() > 0) { tmp = true; }
                else {
                    for (var i=0;i<4;i++) {
                        if (findmove(i) != -1) {
                            tmp = true;
                            break;
                        }
                    }
                }
                if (!tmp) {
                    state = 2;
                }
            }
        }
    }
    game = {
        "ver" => 1,
        "state" => state,
        "deck" => deck,
        "stack" => stack,
        "wild" => wild,
        "wilds" => wilds,
        "rems" => rems,
    };
    Storage.setValue("game",game);
}

function loadgame() {
    game = Storage.getValue("game");
//game = null;
    if (game == null) { 
        wilds = 2;
        newgame();
    }
    gamehist = Storage.getValue("gamehist");
    if (gamehist == null) { 
        gamehist = [];
    }
    lastgame = deepcopy(game);
}

function undo() {
    gamehist = Storage.getValue("gamehist");
    tmp = gamehist.size();
    if (tmp > 0) {
        game = deepcopy(gamehist[tmp-1]);
        gamehist = gamehist.slice(null,-1);
        Storage.setValue("gamehist",gamehist);
        Storage.setValue("game",game);
        return true;
    }
    return false;
}

function deal() as Void {
    if (deck.size() == 0) { return; }
    for (var i=0;i<4;i++) {
        calcoverlap(i);
        tmp = stack[i].size();
        tmp = [stackXY[i][0],stackXY[i][1]+(tmp)*overlap];
        path.add([deck[i],i,calcpath(deckXY,tmp)]);
    }
    deck = deck.slice(4,null);
    moving = true;
    dealing = true;
}

function play(s) as Boolean {
    var d = findmove(s);
    if (d == -1) { return false; }
    if (stack[d].size() == 0) {
        movecard(s,d);
        return true;
    }
    rem(s,d);
    return true;
}

function findmove(s) as Number {
    var l1,l2,s1,s2,v1,v2,besti,bestv,ftmp;
    l1 = stack[s].size();
    if (l1 == 0) { return -1; }
    besti = -1;
    bestv = 0;
    ftmp = stack[s][l1-1];
    s1 = ftmp.substring(1,2);
    v1 = value(ftmp);
    for (var i=0;i<4;i++) {
        l2 = stack[i].size();
        if (l2 > 0) {
            if (i == s) {
                if (l2 > 1) {
                    ftmp = stack[i][l2-2];
                    s2 = ftmp.substring(1,2);
                    v2 = value(ftmp);
                } else {
                    s2 = "X";
                    v2 = 0;
                }
            } else {
                ftmp = stack[i][l2-1];
                s2 = ftmp.substring(1,2);
                v2 = value(ftmp);
            }
            if (s2.equals(s1) and v2 > v1 and bestv < v2) {
                bestv = v2;
                besti = i;
            }
        }
    }
    if (besti == -1) {
        for (var i=0;i<4;i++) {
            if (stack[i].size() == 0) {
                besti = i;
            }
        }
    }
    return besti;
}

function playwild(s) as Boolean {
    tmp = stack[s].size();
    if (tmp == 0) { return false; }
    if (stack[s][tmp-1].substring(0,1).equals("A")) { return false; }
    rem(-1,s);
    return true;
}

function movecard(i1,i2) {
    calcoverlap(i1);
    if (i1 == -1) {
        tmp = deck.size();
        tmp2 = deck[tmp-1];
        tmp3 = [wildXY[0],wildXY[1]+(tmp-1)*overlap];
        deck = deck.slice(null,-1);
    } else {
        tmp = stack[i1].size();
        tmp2 = stack[i1][tmp-1];
        tmp3 = [stackXY[i1][0],stackXY[i1][1]+(tmp-1)*overlap];
        stack[i1] = stack[i1].slice(null,-1);
    }
    calcoverlap(i2);
    tmp = stack[i2].size();
    tmp = [stackXY[i2][0],stackXY[i2][1]+(tmp)*overlap];
    path.add([tmp2,i2,calcpath(tmp3,tmp)]);
    moving = true;
}

function rem(i1,i2) {
    calcoverlap(i1);
    if (i1 == -1) {
        tmp = wild.size();
        tmp2 = wild[tmp-1];
        tmp3 = [wildXY[0],wildXY[1]+(tmp-1)*overlap];
        wild = wild.slice(null,-1);
    } else {
        tmp = stack[i1].size();
        tmp2 = stack[i1][tmp-1];
        tmp3 = [stackXY[i1][0],stackXY[i1][1]+(tmp-1)*overlap];
        stack[i1] = stack[i1].slice(null,-1);
    }
    calcoverlap(i2);
    tmp4 = stack[i2].size();
    tmp = [stackXY[i2][0],stackXY[i2][1]+(tmp4-1)*overlap];
    if (wilding) {
        // move i1 and i2 off screen
        path.add([tmp2,-2,calcpath(tmp3,offscreen)]);
        tmp2 = stack[i2][tmp4-1];
        stack[i2] = stack[i2].slice(null,-1);
        path.add([tmp2,-2,calcpath(tmp,offscreen)]);
    } else {
        // move i1 to i2 then off screen (i2 doesn't change)
        tmp = [tmp[0],tmp[1]+cardR];
        tmp3 = calcpath(tmp3,tmp);
        path.add([tmp2,-2,tmp3.addAll(calcpath(tmp,offscreen))]);
    }
    moving = true;
    wilding = false;

    rems++;
    switch (wilds) {
        case 3:
            if (rems == 36) { addwild(); }
        case 2:
            if (rems == 24) { addwild(); }
        case 1:
            if (rems == 12) { addwild(); } 
    }
}

function addwild() {
    calcoverlap(-1);
    tmp = wild.size();
    tmp = [wildXY[0],wildXY[1]+(tmp)*overlap];
    path.add(["W",-1,calcpath(offscreen,tmp)]);
}

function calcpath(xy1,xy2) {
    var x1 = xy1[0];
    var y1 = xy1[1];
    var x2 = xy2[0];
    var y2 = xy2[1];
    var a = [];
    if (animation != 2) {
        a.add(xy1);
    }
    if (animation == 0) {
        a.add([(x1*3+x2)/4,(y1*3+y2)/4]);
    }
    if (animation != 2) {
        a.add([(x1+x2)/2,(y1+y2)/2]);
    }
    if (animation == 0) {
        a.add([(x1+x2*3)/4,(y1+y2*3)/4]);
    }
    a.add(xy2);
    return a;
}

function value(c as String) as Number {
    // return the value of the given card
    switch (c.substring(0,1)) {
        case "A": return 14;
        case "2": return 2;
        case "3": return 3;
        case "4": return 4;
        case "5": return 5;
        case "6": return 6;
        case "7": return 7;
        case "8": return 8;
        case "9": return 9;
        case "T": return 10;
        case "J": return 11;
        case "Q": return 12;
        case "K": return 13;
    }
    return 0;
}

function calcoverlap(s) {
    var tmp,tmp2;
    overlap = cardWH[1]/2;
    if (s == -1) { return; }
    tmp = stack[s].size();
    tmp2 = newXY[1]*98/100 - (stackXY[s][1]+cardWH[1]+(tmp-1)*overlap);
    if (tmp2 < 0) {
        overlap = overlap + tmp2/(tmp-1);
    }
}

function commas(whole) {
    if (whole == 0) { return "0"; }
    var digits = [];
    
    var count = 0;
    while (whole != 0) {
        var digit = (whole % 10).toString();
        whole /= 10;
        
        if (count == 3) {
            digits.add(",");
            count = 0;
        }
        ++count;
        
        digits.add(digit);
    }
    
    digits = digits.reverse();
    
    whole = "";
    for (var i = 0; i < digits.size(); ++i) {
        whole += digits[i];
    }

    return whole;
}

function savestats(r) {
    stats = Storage.getValue("stats");
    if (stats == null) {
        // [count, current streak, high streak]
        stats = {
            "wins" => [0,0,0],
            "losses" => [0,0,0],
            "last" => 0
        };
    }
    var wins = stats.get("wins");
    var losses = stats.get("losses");
    var last = stats.get("last");
    switch (r) {
        case 0:
            break;
        case 1:
            wins[0]++;
            if (last == 1) {
                wins[1]++;
                if (wins[1] > wins[2]) {
                    wins[2] = wins[1];
                }
            } else { wins[1] = 1; }
            last = 1;
            break;
        case -1:
            losses[0]++;
            if (last == -1) {
                losses[1]++;
                if (losses[1] > losses[2]) {
                    losses[2] = losses[1];
                }
            } else { losses[1] = 1; }
            last = -1;
            break;
    }
    stats.put("wins",wins);
    stats.put("losses",losses);
    stats.put("last",last);
    Storage.setValue("stats",stats);
}

function showstats() {
    var stats = Storage.getValue("stats") as Dictionary;
    if (stats == null) { return; }
    var menu = new WatchUi.CustomMenu(40*SH/454, Graphics.COLOR_BLACK,{
        :title => new $.DrawableMenuTitle(),
        :titleItemHeight => 70*SH/454
    });
    var w = stats.get("wins");
    var l = stats.get("losses");
    var t = w[0]+l[0];
    var wp = w[0]*100/t;
    var lp = l[0]*100/t;
    menu.addItem(new $.CustomItem(0,"Wins",commas(w[0])));
    menu.addItem(new $.CustomItem(0,"Win Pct",wp+"%"));
    menu.addItem(new $.CustomItem(0,"Streak",w[1]));
    menu.addItem(new $.CustomItem(0,"Best",w[2]));
    menu.addItem(new $.CustomItem(1,"Losses",commas(l[0])));
    menu.addItem(new $.CustomItem(1,"Loss Pct",lp+"%"));
    menu.addItem(new $.CustomItem(1,"Streak",l[1]));
    menu.addItem(new $.CustomItem(1,"Worst",w[2]));
    WatchUi.pushView(menu, new $.AcesUpStatsDelegate(), WatchUi.SLIDE_UP);
    WatchUi.requestUpdate();
}

function deepcopy(input)
{
    var result = null;

    if (input == null) {
        // do nothing
    }
    if (input instanceof Lang.Array) {
        if (input.size() == 0) { result = []; }
        else {
            result = new [ input.size() ];
            for (var i = 0; i < result.size(); ++i) {
                result[i] = deepcopy(input[i]);
            }
        }
    }
    else if (input instanceof Lang.Dictionary) {
        var keys = input.keys();
        var vals = input.values();

        result = {};
        for (var i = 0; i < keys.size(); ++i) {
            var key_copy = deepcopy(keys[i]);
            var val_copy = deepcopy(vals[i]);
            result.put(key_copy, val_copy);
        }
    }
    else if (input instanceof Lang.String) {
        return input.substring(0, input.length());
    }
//    else if (input instanceof Lang.ByteArray) {
//        result = input.slice(null, null);
//    }
    else if (input instanceof Lang.Long) {
        return 1 * input;
        
    }
    else if (input instanceof Lang.Double) {
        return 1.0 * input;
    }
    else {
        // primitive types (Number/Float/Boolean/Char) are always copied
        result = input;
    }

    return result;
}



class AcesUpStatsDelegate extends WatchUi.Menu2InputDelegate {
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) {
        return;
    }

    public function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class DrawableMenuTitle extends WatchUi.Drawable {
    public function initialize() {
        Drawable.initialize({});
    }
    
    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(dc.getWidth()/2,(dc.getHeight()*.7).toNumber(),Graphics.FONT_SMALL,"Statistics",center);
        dc.setPenWidth(3);
        dc.drawLine(0,dc.getHeight(),dc.getWidth(),dc.getHeight());
    }
}

class CustomItem extends WatchUi.CustomMenuItem {
    private var _id as Number;
    private var _label as String;
    private var _value as String;

    public function initialize(id as Number, label as String, value as String) {
        CustomMenuItem.initialize(id, {});
        _id = id;
        _label = label;
        _value = value;
    }

    public function draw(dc as Dc) as Void {
        // Fill background horizontally based on percentage
        var w = dc.getWidth();
        var h = dc.getHeight();
        var bx = w/8;
        var bw = w*6/8;
        var lx = bx;
        var vx = bx+bw;
        if (_id == 0) { dc.setColor(wincolor,-1); }
        else { dc.setColor(losecolor,-1); }
        dc.drawText(lx,h/2,Graphics.FONT_TINY,_label,left);
        dc.drawText(vx,h/2,Graphics.FONT_TINY,_value,right);
    }
}

class AcesUpSettings extends WatchUi.Menu2 {
    public function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("Settings");

        var themeicon = new $.CustomIcon(theme);
        var scicon = new $.CustomIcon(suitcolor);
        var bgicon = new $.CustomIcon(background);
        var anicon = new $.CustomIcon(animation);
        var statsicon = new $.CustomIcon(0);

        Menu2.addItem(new WatchUi.IconMenuItem("Theme", themes[theme], "theme", themeicon, null));
        Menu2.addItem(new WatchUi.IconMenuItem("Suit Colors", suitcolors[suitcolor], "suitcolor", scicon, null));
        Menu2.addItem(new WatchUi.IconMenuItem("Background", backgrounds[background], "background", bgicon, null));
        Menu2.addItem(new WatchUi.IconMenuItem("Animations", animations[animation], "animation", anicon, null));
        Menu2.addItem(new WatchUi.IconMenuItem("Stats", "Show statistics", "stats", statsicon, null));
    }
}

class CustomIcon extends WatchUi.Drawable {
    private var _index as Number;

    public function initialize(index as Number) {
        _index = index;
        Drawable.initialize({});
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(-1,-1);
        dc.clear();
    }
}
