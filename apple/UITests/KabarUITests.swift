import XCTest
final class KabarUITests: XCTestCase {
    func testSenderFlowAndEditableButtons() throws {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["-KabarQAClean"]; app.launch()
        XCTAssertTrue(app.buttons["Aku membagikan kabar"].waitForExistence(timeout:15)); app.buttons["Aku membagikan kabar"].tap()
        XCTAssertTrue(app.buttons["home"].waitForExistence(timeout:10))
        // Pause delivery to verify the persistent offline queue through actual taps.
        app.tabBars.buttons["Pengaturan"].tap();app.buttons["Jeda koneksi"].tap();app.tabBars.buttons["Beranda"].tap()
        app.swipeUp();app.buttons["home"].tap();app.buttons["meal"].tap();app.buttons["outside"].tap()
        app.swipeDown();XCTAssertTrue(app.staticTexts["Keluar"].firstMatch.waitForExistence(timeout:5))
        app.tabBars.buttons["Riwayat"].tap();XCTAssertTrue(app.staticTexts["Di kost"].exists)
        app.tabBars.buttons["Pengaturan"].tap();app.buttons["Edit nama, tombol & jam makan"].tap()
        let fields=app.textFields
        XCTAssertTrue(fields["Kost"].waitForExistence(timeout:5))
        let home=fields["Kost"];home.tap();home.press(forDuration:1.2)
        if app.menuItems["Select All"].waitForExistence(timeout:2) { app.menuItems["Select All"].tap();home.typeText("Rumah") }
        else { home.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:4)+"Rumah") }
        app.navigationBars.buttons["Simpan"].tap();app.tabBars.buttons["Beranda"].tap();app.swipeUp()
        XCTAssertTrue(app.buttons["home"].waitForExistence(timeout:5));app.buttons["home"].tap()
        app.tabBars.buttons["Riwayat"].tap();XCTAssertTrue(app.staticTexts["Di rumah"].waitForExistence(timeout:5))
        app.terminate();app.launchArguments=[];app.launch();app.tabBars.buttons["Riwayat"].tap()
        XCTAssertTrue(app.staticTexts["Di rumah"].waitForExistence(timeout:5))
    }
}
