import XCTest
final class KabarUITests: XCTestCase {
    func testSenderFlowAndEditableButtons() throws {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["-KabarQAClean"]; app.launch()
        let opened=app.buttons["sender-setup"].waitForExistence(timeout:40)
        let screenshot=XCTAttachment(screenshot:app.screenshot());screenshot.name="Kabar initial screen";screenshot.lifetime = .keepAlways;add(screenshot)
        XCTAssertTrue(opened,app.debugDescription);app.buttons["sender-setup"].tap()
        // The status controls are below the fold on iPhone; verify navigation before scrolling.
        XCTAssertTrue(app.tabBars.buttons["Beranda"].waitForExistence(timeout:15),app.debugDescription)
        // Pause delivery to verify the persistent offline queue through actual taps.
        app.tabBars.buttons["Pengaturan"].tap();app.buttons["Jeda koneksi"].tap();app.tabBars.buttons["Beranda"].tap()
        app.swipeUp();app.buttons["home"].tap();app.buttons["meal"].tap();app.buttons["outside"].tap()
        app.swipeDown();XCTAssertTrue(app.staticTexts["Keluar"].firstMatch.waitForExistence(timeout:5))
        app.tabBars.buttons["Riwayat"].tap();XCTAssertTrue(app.staticTexts["Di kost"].exists)
        app.tabBars.buttons["Pengaturan"].tap();app.buttons["Edit nama, tombol & jam makan"].tap()
        let fields=app.textFields
        XCTAssertTrue(fields["Kost"].waitForExistence(timeout:5))
        let home=fields["Kost"];home.tap();home.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:4)+"Rumah")
        app.navigationBars.buttons["Simpan"].tap();app.tabBars.buttons["Beranda"].tap();app.swipeUp()
        XCTAssertTrue(app.buttons["home"].waitForExistence(timeout:5));app.buttons["home"].tap()
        app.tabBars.buttons["Riwayat"].tap();XCTAssertTrue(app.staticTexts["Di rumah"].waitForExistence(timeout:5))
        app.terminate();app.launchArguments=[];app.launch();app.tabBars.buttons["Riwayat"].tap()
        XCTAssertTrue(app.staticTexts["Di rumah"].waitForExistence(timeout:5))
        let final=XCTAttachment(screenshot:app.screenshot());final.name="Kabar edited history";final.lifetime = .keepAlways;add(final)
    }
}
