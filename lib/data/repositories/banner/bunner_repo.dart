import 'dart:async';
const FREQUENCY_BUNNER_VIEW_IN_SECONDS=10;

class BannerRepo{

  Timer? timer;

  StreamController<String> _myStreamController = StreamController();
  Stream<String> get myStream => _myStreamController.stream;

  bool isViewBunner=false;
  


  startTimer(){
    int seconds = 0;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if(isViewBunner){
        timer.cancel();
      } 
       seconds=seconds+1;
        if(seconds==FREQUENCY_BUNNER_VIEW_IN_SECONDS){
          isViewBunner=true;
          _myStreamController.sink.add("view");
          timer.cancel();
        }
    });
  //  Future.delayed(Duration(seconds: 3), () { 
  //     isViewBunner=true;
  //     _myStreamController.sink.add("view");
  //   });
  }
  viewBunner(){
    if(isViewBunner){
      return;
    }
      isViewBunner=true;
      _myStreamController.sink.add("view");
  }
  void dispose() {
    _myStreamController.close();
    _myStreamController = StreamController<String>();
    
  }

}

BannerRepo bunnerRepo=BannerRepo();