#!/usr/bin/false

import numpy as np
from numba import jit

# Computes hash functions within the H3 family of integer-integer hashing functions,
#  as described by Carter and Wegman in the paper "Universal Classes of Hash Functions"
# This function requires more unique parameters than the Dietzfelbinger multiply-shift hash function, but avoids arithmetic
# Inputs:
#  xv: A bitvector to be hashed to an integer
#  m: An array of arrays of length equivalent to the length of xv, with entries of size equivalent to the hash size
@jit(nopython=True)
def h3_hash(xv, m):
    #selected_entries = np.where(xv, m, 0)
    selected_entries = xv * m # np.where is unsupported in Numba
    #reduction_result = np.bitwise_xor.reduce(selected_entries, axis=1)
    reduction_result = np.zeros(m.shape[0], dtype=np.int64) # ".reduce" is unsupported in Numba
    for i in range(m.shape[1]):
        reduction_result ^= selected_entries[:,i]
    return reduction_result

# Implements a Bloom filter, a data structure for approximate set membership
# A Bloom filter can return one of two results: "possibly a member", and "definitely not a member"
# The risk of false positives increases with the number of elements stored relative to the underlying array size
# This implementation generalizes the basic concept to incorporate the notion of bleaching from WNN research
# With bleaching, we replace seen/not seen bits in the data structure with counters
# Elements can now be added to the data structure multiple times
# Our results now become "possibly added at least <b> times" and "definitely added fewer than <b> times"
# Increasing the bleaching threshold (the value of b) can improve accuracy
# Once the final bleaching threshold has been selected, this can be converted to a traditional Bloom filter
#  by evaluating the predicate "d[i] >= b" for all entries in the filter's data array
class BloomFilter:
    # Constructor
    # Inputs:
    #  num_inputs:     The bit width of the input to the filter (assumes the underlying inputs are single bits)
    #  num_entries:    The size of the underlying array for the filter. Must be a power of two. Increasing this reduces the risk of false positives.
    #  num_hashes:     The number of hash functions for the Bloom filter. This has a complex relation with false-positive rates
    #  hash_constants: Constant parameters for H3 hash
    def __init__(self, num_inputs, num_entries, num_hashes, hash_constants):
        self.num_inputs, self.num_entries, self.num_hashes = num_inputs, num_entries, num_hashes
        self.hash_values = hash_constants
        self.index_bits = int(np.log2(num_entries))
        self.data = np.zeros(num_entries, dtype=int)
        self.bleach = np.array(1, dtype=int)

    # Implementation of the check_membership function
    # Coding in this style (as a static method) is necessary to use Numba for JIT compilation
    @staticmethod
    @jit(nopython=True)
    def __check_membership(xv, hash_values, bleach, data):
        #hash_results = dietzfelbinger_hash(x, a_values, b_values, num_inputs, index_bits)
        hash_results = h3_hash(xv, hash_values)
        least_entry = data[hash_results].min() # The most times the entry has possibly been previously seen
        return least_entry >= bleach

    # Check whether a value is a member of this filter (i.e. possibly seen at least b times)
    # Inputs:
    #  xv:              The bitvector to check the membership of
    # Returns: A boolean, which is true if xv has possibly been seen at least b times, and false if it definitely has not been
    def check_membership(self, xv):
        return BloomFilter.__check_membership(xv, self.hash_values, self.bleach, self.data)
   
    # Implementation of the add_member function
    # Coding in this style (as a static method) is necessary to use Numba for JIT compilation
    @staticmethod
    @jit(nopython=True)
    def __add_member(xv, hash_values, data):
        hash_results = h3_hash(xv, hash_values)
        least_entry = data[hash_results].min() # The most times the entry has possibly been previously seen
        data[hash_results] = np.maximum(data[hash_results], least_entry+1) # Increment upper bound

    # Register a bitvector / increment its encountered count in the filter
    # Inputs:
    #  xv: The bitvector
    def add_member(self, xv):
        BloomFilter.__add_member(xv, self.hash_values, self.data)

    # Set the bleaching threshold, which is used to exclude members which have not possibly been seen at least b times
    # Inputs:
    #  bleach: The new value for b
    def set_bleaching(self, bleach):
        self.bleach[...] = bleach

    # Converts the filter into a "canonical" Bloom filter, with all entries either 0 or 1 and bleaching of 1
    # This operation will not impact the result of the check_membership function for any input
    # This operation is irreversible, so shouldn't be done until the optimal bleaching value has been selected
    def binarize(self):
        self.data = (self.data >= self.bleach).astype(int)
        self.set_bleaching(1)

