import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Storage;

class AcesUpDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new AcesUpSettings(), new AcesUpMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onTap(clickEvent) as Boolean {
        var xy = clickEvent.getCoordinates();
        if (moving) { return false; }
        switch (state) {
            case 0:
                // New round
                if (inbox(xy,themeXY,themeWH)) {
                    theme = Storage.getValue("theme");
                    if (theme == null) { theme = 0; }
                    theme = (theme + 1) % themes.size();
                    Storage.setValue("theme",theme);
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,suitsXY,suitsWH)) {
                    suitcolor = Storage.getValue("suitcolor");
                    if (suitcolor == null) { suitcolor = 0; }
                    suitcolor = (suitcolor + 1) % suitcolors.size();
                    Storage.setValue("suitcolor",suitcolor);
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,bgXY,bgWH)) {
                    background = Storage.getValue("background");
                    if (background == null) { background = 0; }
                    background = (background + 1) % backgrounds.size();
                    Storage.setValue("background",background);
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,wildsXY,wildsWH)) {
                    wilds = (wilds + 1) % 4;
                    savegame(false);
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,startXY,startWH)) {
                    state = 1;
                    juststarted = true;
                    deal();
                    savegame(false);
                    WatchUi.requestUpdate();
                    return true;
                }
                break;
            case 1:
                // Playing
                for (var i=0;i<4;i++) {
                    calcoverlap(i);
                    tmp = stack[i].size();
                    if (tmp > 0) {
                        if (inbox(xy,[stackXY[i][0],stackXY[i][1]+(tmp-1)*overlap],cardWH)) {
                            if (wilding) {
                                tmp = playwild(i);
                            } else {
                                tmp = play(i);
                            }
                            if (tmp) {
                                savegame(false);
                                WatchUi.requestUpdate();
                                return true;
                            }
                            return false;
                        }
                    }
                }
                if (inbox(xy,deckXY,cardWH) and deck.size() > 0) {
                    deal();
                    WatchUi.requestUpdate();
                    savegame(false);
                    return true;
                }
                tmp = wild.size();
                if (tmp > 0) {
                    calcoverlap(-1);
                    if (inbox(xy,[wildXY[0],wildXY[1]+(tmp-1)*overlap],cardWH)) {
                        wilding = !wilding;
                        WatchUi.requestUpdate();
                        return true;
                    }
                }
                if (inbox(xy,undoXY,undoWH)) {
                    if (undo()) {
                        WatchUi.requestUpdate();
                        return true;
                    }
                    return false;
                }
                if (inbox(xy,newXY,newWH)) {
                    newgame();
                    WatchUi.requestUpdate();
                    return true;
                }
                break;
            case 2:
                // No more moves
                if (inbox(xy,undoXY,undoWH)) {
                    if (undo()) {
                        WatchUi.requestUpdate();
                        return true;
                    }
                    return false;
                }
                if (inbox(xy,undoXY,undoWH)) {
                    if (undo()) {
                        WatchUi.requestUpdate();
                        return true;
                    }
                    return false;
                }
                if (inbox(xy,newXY,newWH)) {
                    savestats(-1);
                    newgame();
                    WatchUi.requestUpdate();
                    return true;
                }
                break;
            case 3:
                // Winner
                if (inbox(xy,undoXY,undoWH)) {
                    if (undo()) {
                        WatchUi.requestUpdate();
                        return true;
                    }
                    return false;
                }
                if (inbox(xy,startXY,startWH)) {
                    savestats(1);
                    newgame();
                    WatchUi.requestUpdate();
                    return true;
                }
                break;
        }
        return false;
    }

    // Check if a point is within a box
    // boxxy = [x,y] coordinates of center of box
    // boxwh = [w,h] width and height of box
    // point = [x,y] coordinates of point to check
    function inbox(point,boxxy,boxwh) as Boolean {
        var bx = boxxy[0]-boxwh[0]/2;
        var by = boxxy[1]-boxwh[1]/2;
        if (point[0]<bx) {return false;}
        if (point[0]>bx+boxwh[0]) {return false;}
        if (point[1]<by) {return false;}
        if (point[1]>by+boxwh[1]) {return false;}
        return true;
    }
}
