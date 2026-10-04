import 'dart:io';
import 'dart:ui' as ui;
import 'package:abc/model.dart';
import 'package:abc/pixels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class EmptyBackend extends Backend {
  @override Future<Map<String,dynamic>> invoke(String method,[Map<String,dynamic> args=const {}])async=>{};
}
void main(){
  test('meal routing respects customized local windows and exclusive end boundaries',(){
    final model=AppModel(EmptyBackend())..snapshot={'state':{'windows':[5,10,11,14,17,22]}};
    for(final entry in {4:'Makan',5:'Sarapan',9:'Sarapan',10:'Makan',11:'Makan siang',14:'Makan',18:'Makan malam',22:'Makan'}.entries){
      expect(model.mealNow(DateTime(2026,10,3,entry.key)),entry.value);
    }
    model.dispose();
  });
  testWidgets('all 24 action, theme and time scenes differ; action motion changes pixels',(tester)async{
    tester.view.physicalSize=const Size(500,300);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final hashes=<int>{};
    for(final together in [false,true]){
      for(final hour in [8,12,16,20]){
        for(final action in ['outside','home','meal']){
          final key=GlobalKey();
          await tester.pumpWidget(MaterialApp(home:Center(child:RepaintBoundary(key:key,child:SizedBox(width:400,height:160,child:PixelSky(action:action,together:together,at:DateTime(2026,10,3,hour),animate:true))))));
          await tester.pump();
          Future<int> capture(String suffix)async{
            final boundary=key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final image=boundary.toImageSync();
            final hash=await tester.runAsync(()async{
              final raw=(await image.toByteData())!;
              final bytes=raw.buffer.asUint8List();
              final colors=<int>{};
              for(var i=0;i<bytes.length;i+=4){
                colors.add(bytes[i]<<16|bytes[i+1]<<8|bytes[i+2]);
              }
              expect(colors.length,greaterThan(45),reason:'Each world has layered lighting and detailed props');
              if(const bool.fromEnvironment('QA_ART')){
                final png=(await image.toByteData(format:ui.ImageByteFormat.png))!;
                final folder=Directory('qa-screenshots/scenes');await folder.create(recursive:true);
                await File('${folder.path}/${together?'seirama':'default'}-$action-$hour-$suffix.png').writeAsBytes(png.buffer.asUint8List());
              }
              return Object.hashAll(raw.buffer.asUint8List());
            });image.dispose();return hash!;
          }
          final first=await capture('still');expect(hashes.add(first),true,reason:'$together/$hour/$action must be distinct');
          await tester.pump(const Duration(seconds:1));final next=await capture('motion');expect(next,isNot(first));
        }
      }
    }
    await tester.pumpWidget(const SizedBox());await tester.pump();
  });
  testWidgets('action change blends into the new world and reduced motion skips the blend',(tester)async{
    final state=GlobalKey<PixelSkyState>(), imageKey=GlobalKey();
    Widget scene(String action,{bool animate=true,bool reduced=false})=>MaterialApp(home:MediaQuery(
      data:MediaQueryData(size:const Size(800,600),disableAnimations:reduced),
      child:Center(child:RepaintBoundary(key:imageKey,child:SizedBox(width:400,height:160,
        child:PixelSky(key:state,action:action,at:DateTime(2026,10,4,20),animate:animate))))));
    Future<int> capture()async{
      final boundary=imageKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image=boundary.toImageSync();
      final hash=await tester.runAsync(()async=>Object.hashAll((await image.toByteData())!.buffer.asUint8List()));
      image.dispose();return hash!;
    }
    await tester.pumpWidget(scene('outside',animate:false));
    final before=await capture();
    await tester.pumpWidget(scene('home'));
    expect(state.currentState!.frame,0);
    expect(await capture(),before,reason:'The first transition frame preserves the previous world');
    await tester.pump(const Duration(milliseconds:332));
    final blending=await capture();expect(blending,isNot(before));
    await tester.pump(const Duration(milliseconds:332));
    expect(await capture(),isNot(blending));
    await tester.pumpWidget(scene('outside',animate:false,reduced:true));
    expect(await capture(),before,reason:'Reduce Motion displays the new world immediately');
    await tester.pumpWidget(const SizedBox());await tester.pump();
  });
  testWidgets('outside walking loop crosses its boundary without a scene-sized jump',(tester)async{
    final state=GlobalKey<PixelSkyState>(), imageKey=GlobalKey();
    await tester.pumpWidget(MaterialApp(home:Center(child:RepaintBoundary(key:imageKey,
      child:SizedBox(width:320,height:128,child:PixelSky(key:state,action:'outside',
        together:true,at:DateTime(2026,10,4,8),animate:true))))));
    Future<List<int>> capture()async{
      final boundary=imageKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image=boundary.toImageSync();
      final bytes=await tester.runAsync(()async=>(await image.toByteData())!.buffer.asUint8List().toList());
      image.dispose();return bytes!;
    }
    await tester.pump(const Duration(milliseconds:83*119));
    expect(state.currentState!.frame,119);
    final last=await capture();
    await tester.pump(PixelSkyState.frameInterval);
    expect(state.currentState!.frame,0);
    final first=await capture();
    var changed=0;
    for(var i=0;i<last.length;i+=4){
      if(last[i]!=first[i]||last[i+1]!=first[i+1]||last[i+2]!=first[i+2])changed++;
    }
    expect(changed/(last.length/4),lessThan(.08),reason:'Sprites and scenery remain continuous at the loop boundary');
    await tester.pumpWidget(const SizedBox());await tester.pump();
  });
}
