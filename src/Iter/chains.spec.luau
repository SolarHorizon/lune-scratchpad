local Iter = require("Iter")

local Chain = require("./Chain")

return function()
	describe("Chain", function()
		it("should chain iterable values", function()
			local chain = Chain.new({ 1, 2, 3 }, { 4, 5, 6 })

			local c = 0

			for k, v in chain do
				c += 1
			end

			expect(c).to.be.equal(6)
		end)

		it("should support the __len metamethod", function()
			local chain = Chain.new({ 1, 2, 3 }, { 4, 5, 6 })
			expect(#chain).to.be.equal(6)
		end)
	end)

	describe("chain", function()
		it("should chain two iterators", function()
			local t1 = { 1, 2, 3 }
			local t2 = { 4, 5, 6 }

			local c = 0
			local max = #t1 + #t2 + 1

			local iter = Iter.new(t1):chain(Iter.new(t2))

			local k

			repeat
				expect(c < max).to.be.equal(true)
				k = iter:next()
				c += 1
			until k == Iter.None

			expect(c).to.be.equal(max)
		end)

		it("should support folding", function()
			local a = { 1, 2, 3 }
			local b = { 4, 5, 6 }

			local i = Iter.new(a):chain(Iter.new(b))
			local next = { i:next() }

			while next[1] ~= Iter.None do
				next = { i:next() }
			end

			local sum = Iter.new(a)
				:chain(Iter.new(b))
				:fold(0, function(acc, y, x)
					return acc + x
				end)

			expect(sum).to.be.equal(1 + 2 + 3 + 4 + 5 + 6)
		end)

		it("should support tryFold", function()
			local numbers = { 1, 2, 3, 4 }
			local others = { 5, 6, 7, 8 }

			local iterator = Iter.new(numbers):chain(Iter.new(others))

			local result = iterator:tryFold("0", function(acc, y, x)
				if x == 6 then
					return nil
				end
				return `({acc} + {x})`
			end)

			expect(result).to.be.equal(Iter.None)

			local _, v = iterator:next()
			expect(v).to.be.equal(7)
		end)

		it("should support multiple chains", function()
			local t1 = { 1, 2, 3 }
			local t2 = { 4, 5, 6 }
			local t3 = { 7, 8, 9 }
			local t4 = { 10, 11, 12 }

			local c = 0
			local max = #t1 + #t2 + #t3 + #t4

			local iter = Iter.new(t1)
				:chain(Iter.new(t2))
				:chain(Iter.new(t3))
				:chain(Iter.new(t4))

			iter:fold(0, function(x, k, v)
				c += 1
				return x
			end)

			expect(c).to.be.equal(max)
		end)
	end)
end
