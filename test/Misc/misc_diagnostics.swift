// RUN: %target-typecheck-verify-swift

// REQUIRES: objc_interop

import Foundation
import CoreGraphics

var roomName : String?

if let realRoomName = roomName as! NSString { // expected-warning{{forced cast from 'String?' to 'NSString' only unwraps and bridges; did you mean to use '!' with 'as'?}}
  // expected-error@-1{{initializer for conditional binding must have Optional type, not 'NSString'}}
  // expected-warning@-2{{treating a forced downcast to 'NSString' as optional will never produce 'nil'}}
  // expected-note@-3{{add parentheses around the cast to silence this warning}}
  // expected-note@-4{{use 'as?' to perform a conditional downcast to 'NSString'}}
  _ = realRoomName
}

var pi = 3.14159265358979
var d: CGFloat = 2.0
var dpi:CGFloat = d*pi // Ok (implicit conversion Float -> CGFloat)

let ff: CGFloat = floorf(20.0) // expected-error{{cannot convert value of type 'Float' to specified type 'CGFloat'}}
let _: CGFloat = floor(20.0) // Ok (Double -> CGFloat) conversion

let total = 15.0
let count = 7
let median = total / count // expected-error {{binary operator '/' cannot be applied to operands of type 'Double' and 'Int'}} expected-note {{overloads for '/' exist with these partially matching parameter lists:}}

if (1) {} // expected-error{{type 'Int' cannot be used as a boolean; test for '!= 0' instead}}
if 1 {} // expected-error {{type 'Int' cannot be used as a boolean; test for '!= 0' instead}}

var a: [String] = [1] // expected-error{{cannot convert value of type 'Int' to expected element type 'String'}}
var b: Int = [1, 2, 3] // expected-error{{cannot convert value of type '[Int]' to specified type 'Int'}}

var f1: Float = 2.0
var f2: Float = 3.0

var dd: Double = f1 - f2 // expected-error{{cannot convert value of type 'Float' to specified type 'Double'}}

func f() -> Bool {
  return 1 + 1 // expected-error{{type 'Int' cannot be used as a boolean; test for '!= 0' instead}}
}

// Test that nested diagnostics are properly surfaced.
func takesInt(_ i: Int) {}
func noParams() -> Int { return 0 }
func takesAndReturnsInt(_ i: Int) -> Int { return 0 }

takesInt(noParams(1)) // expected-error{{argument passed to call that takes no arguments}}

takesInt(takesAndReturnsInt("")) // expected-error{{cannot convert value of type 'String' to expected argument type 'Int'}}

// Test error recovery for type expressions.
struct MyArray<Element> {} // expected-note {{'Element' declared as parameter to type 'MyArray'}}
class A {
    var a: MyArray<Int>
    init() {
        a = MyArray<Int // expected-error {{generic parameter 'Element' could not be inferred}} expected-note {{explicitly specify the generic arguments to fix this issue}}
       // expected-error@-1 {{binary operator '<' cannot be applied to operands of type 'MyArray<_>.Type' and 'Int.Type'}}
       // expected-error@-2 {{cannot assign value of type 'Bool' to type 'MyArray<Int>'}}
    }
}

func retV() { return true } 
// expected-error@-1 {{unexpected non-void return value in void function}}
// expected-note@-2 {{did you mean to add a return type?}}

func retAI() -> Int {
    let a = [""]
    let b = [""]
    return (a + b) // expected-error{{cannot convert return expression of type 'Array<String>' to return type 'Int'}}
}

func bad_return1() {
  return 42  
  // expected-error@-1 {{unexpected non-void return value in void function}}
  // expected-note@-2 {{did you mean to add a return type?}}
}

func bad_return2() -> (Int, Int) {
  return 42  // expected-error {{cannot convert return expression of type 'Int' to return type '(Int, Int)'}}
}

// <rdar://problem/14096697> QoI: Diagnostics for trying to return values from void functions
func bad_return3(lhs: Int, rhs: Int) {
  return lhs != 0  
  // expected-error@-1 {{unexpected non-void return value in void function}}
  // expected-note@-2 {{did you mean to add a return type?}}
}

class MyBadReturnClass {
  static var intProperty = 42
}

func ==(lhs:MyBadReturnClass, rhs:MyBadReturnClass) {
  return MyBadReturnClass.intProperty == MyBadReturnClass.intProperty
  // expected-error@-1 {{unexpected non-void return value in void function}}
  // expected-note@-2 {{did you mean to add a return type?}}
}


func testIS1() -> Int { return 0 }
let _: String = testIS1() // expected-error {{cannot convert value of type 'Int' to specified type 'String'}}

func insertA<T>(array : inout [T], elt : T) {
  array.append(T.self); // expected-error {{cannot convert value of type 'T.Type' to expected argument type 'T'}}

  // FIXME: Kind of weird
  array.append(T); // expected-error {{cannot convert value of type 'T.Type' to expected argument type 'T'}}
}

// <rdar://problem/17875634> can't append to array of tuples
func test17875634() {
  var match: [(Int, Int)] = []
  var row = 1
  var col = 2
  var coord = (row, col)

  match += (1, 2) // expected-error{{binary operator '+=' cannot be applied to operands of type '[(Int, Int)]' and '(Int, Int)'}}

  match += (row, col) // expected-error{{binary operator '+=' cannot be applied to operands of type '[(Int, Int)]' and '(Int, Int)'}}

  match += coord // expected-error{{binary operator '+=' cannot be applied to operands of type '[(Int, Int)]' and '(Int, Int)'}}

  match.append(row, col) // expected-error {{instance method 'append' expects a single parameter of type '(Int, Int)'}} {{16-16=(}} {{24-24=)}}

  match.append(1, 2) // expected-error {{instance method 'append' expects a single parameter of type '(Int, Int)'}} {{16-16=(}} {{20-20=)}}

  match.append(coord)
  match.append((1, 2))

  // Make sure the behavior matches the non-generic case.
  struct FakeNonGenericArray {
    func append(_ p: (Int, Int)) {}
  }
  let a2 = FakeNonGenericArray()
  a2.append(row, col) // expected-error {{instance method 'append' expects a single parameter of type '(Int, Int)'}} {{13-13=(}} {{21-21=)}}
  a2.append(1, 2) // expected-error {{instance method 'append' expects a single parameter of type '(Int, Int)'}} {{13-13=(}} {{17-17=)}}
  a2.append(coord)
  a2.append((1, 2))
}

// <rdar://problem/20770032> Pattern matching ranges against tuples crashes the compiler
func test20770032() {
  if case let 1...10 = (1, 1) { // expected-warning{{'let' pattern has no effect; sub-pattern didn't bind any variables}} {{11-15=}}
    // expected-error@-1 {{expression pattern of type 'ClosedRange<Int>' cannot match values of type '(Int, Int)'}}
    // expected-error@-2 {{type '(Int, Int)' cannot conform to 'Equatable'}}
    // expected-note@-3 {{only concrete types such as structs, enums and classes can conform to protocols}}
    // expected-note@-4 {{required by operator function '~=' where 'T' = '(Int, Int)'}}
  }
}



func tuple_splat1(_ a : Int, _ b : Int) { // expected-note 2 {{'tuple_splat1' declared here}}
  let x = (1,2)
  tuple_splat1(x)          // expected-error {{global function 'tuple_splat1' expects 2 separate arguments}}
  tuple_splat1(1, 2)       // Ok.
  tuple_splat1((1, 2))     // expected-error {{global function 'tuple_splat1' expects 2 separate arguments; remove extra parentheses to change tuple into separate arguments}} {{16-17=}} {{21-22=}}
}

// This take a tuple as a value, so it isn't a tuple splat.
func tuple_splat2(_ q : (a : Int, b : Int)) {
  let x = (1,2)
  tuple_splat2(x)          // Ok
  let y = (1, b: 2)
  tuple_splat2(y)          // Ok
  tuple_splat2((1, b: 2))  // Ok.
  tuple_splat2(1, b: 2)    // expected-error {{global function 'tuple_splat2' expects a single parameter of type '(a: Int, b: Int)'}} {{16-16=(}} {{23-23=)}}
}

// SR-1612: Type comparison of foreign types is always true.
func is_foreign(a: AnyObject) -> Bool {
  return a is CGColor // expected-warning {{'is' test is always true because 'CGColor' is a Core Foundation type}}
}

func test_implicit_cgfloat_conversion() {
  func test_to(_: CGFloat) {}
  func test_from(_: Double) {}

  let d: Double    = 0.0
  let f: Float     = 0.0
  let cgf: CGFloat = 0.0

  test_to(d) // Ok (Double -> CGFloat
  test_to(f) // error

  test_from(cgf) // Ok (CGFloat -> Double)
  test_from(f) // error

  let _: CGFloat = d // Ok
  let _: CGFloat = f // error
  let _: Double  = cgf // Ok
  let _: Float   = cgf // error
}
