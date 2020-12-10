import unittest

class NumbersTest(unittest.TestCase):

    def test_equal(self):
        self.assertNotEqual(1 + 1, 1)

if __name__ == '__main__':
    unittest.main()
